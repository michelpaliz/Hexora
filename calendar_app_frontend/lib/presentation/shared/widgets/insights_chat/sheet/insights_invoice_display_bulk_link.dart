import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/services/statements/statements_api.dart';

import '../insights_chat_message.dart';
import '../insights_json_utils.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsInvoiceDisplayBulkLink on InsightsChatSheetStateBase {
  @override
  String formatEuroAmount(num? amount, String? currency) {
    if (amount == null) return '';
    final parts = amount.toStringAsFixed(2).split('.');
    final whole = parts.first;
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final left = whole.length - i;
      buffer.write(whole[i]);
      if (left > 1 && left % 3 == 1) buffer.write('.');
    }
    final code = (currency ?? 'EUR').trim().isEmpty ? 'EUR' : currency!.trim();
    return '${buffer.toString()},${parts.last} $code';
  }

  @override
  Future<void> ensureInvoiceDisplayCacheLoaded() async {
    if (invoiceDisplayCache.isNotEmpty || loadingInvoiceDisplayCache) return;
    loadingInvoiceDisplayCache = true;
    try {
      final invoices = await invoicesApi.listByGroup(
        widget.groupId,
        status: 'issued',
      );
      final clients = await clientsApi.list(groupId: widget.groupId);
      final clientNamesById = {
        for (final client in clients)
          if (client.id.trim().isNotEmpty)
            client.id.trim():
                (client.billing?.legalName?.trim().isNotEmpty == true)
                    ? client.billing!.legalName!.trim()
                    : client.name.trim(),
      };
      for (final invoice in invoices) {
        final id = invoice.id.trim();
        if (id.isEmpty) continue;
        final clientName =
            (invoice.clientSnapshot?.legalName?.trim().isNotEmpty == true)
                ? invoice.clientSnapshot!.legalName!.trim()
                : (invoice.billingName?.trim().isNotEmpty == true)
                    ? invoice.billingName!.trim()
                    : (clientNamesById[invoice.clientId.trim()] ?? '').trim();
        invoiceDisplayCache[id] = <String, dynamic>{
          'id': id,
          'invoiceNumber': invoice.invoiceNumber.trim(),
          'clientName': clientName,
          'total': invoice.total,
          'totalFormatted': formatEuroAmount(invoice.total, invoice.currency),
        };
      }
    } catch (_) {
      // Best-effort fallback; backend hydrated fields remain the source of truth.
    } finally {
      loadingInvoiceDisplayCache = false;
    }
  }

  @override
  Future<void> hydrateLinkedInvoiceDisplayFields(
    ChatMessage message,
    List<Map<String, dynamic>> rows,
    bool isEs,
  ) async {
    final needsHydration = rows
        .where(linkedRowNeedsInvoiceDisplayHydration)
        .toList(growable: false);
    if (needsHydration.isEmpty) return;
    await ensureInvoiceDisplayCacheLoaded();
    if (invoiceDisplayCache.isEmpty) return;

    for (final row in needsHydration) {
      final entryId = rowEntryId(row);
      if (entryId == null) continue;
      final ids = linkedInvoiceIdsFromRow(row);
      final invoices = ids
          .map((id) => invoiceDisplayCache[id])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      if (invoices.isEmpty) continue;

      final numbers = invoices
          .map((invoice) => invoice['invoiceNumber']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
      final clients = invoices
          .map((invoice) => invoice['clientName']?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final total = invoices.fold<num>(
        0,
        (sum, invoice) =>
            sum + ((invoice['total'] is num) ? invoice['total'] as num : 0),
      );

      await runtime.updateTableRow(
        message: message,
        entryId: entryId,
        rowPatch: <String, dynamic>{
          'matchedInvoiceNumber': numbers.join(' + '),
          'matchedInvoiceClientName': clients.join(' + '),
          'matchedInvoiceAmount': total,
          'matchedInvoiceAmountFormatted': formatEuroAmount(total, 'EUR'),
          'linkStatus': 'linked',
          'linkStatusLabel': isEs ? 'Vinculado' : 'Linked',
          'hasExistingInvoiceLink': true,
          'existingLinkedInvoiceIds': ids,
        },
      );
    }
  }

  @override
  Map<String, dynamic> linkedRowPatchFromBulkResponse(
    Map<String, dynamic> item,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((value) => value?.toString().trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(growable: false);
    }

    final entry = safeMap(item['entry']);
    final invoiceIds = stringList(item['invoiceIds']);
    final invoiceNumbers = stringList(item['invoiceNumbers']);
    final invoiceNumber =
        (item['invoiceNumber']?.toString().trim().isNotEmpty == true)
            ? item['invoiceNumber'].toString().trim()
            : invoiceNumbers.join(' + ');
    final clientName = item['clientName']?.toString().trim() ?? '';
    final total = item['total'];
    final totalFormatted = item['totalFormatted']?.toString().trim() ?? '';

    return <String, dynamic>{
      if (entry != null) ...entry,
      'bulkLinkEntry': entry,
      'matchedInvoiceId': invoiceIds.isNotEmpty ? invoiceIds.first : null,
      'matchedInvoiceIds': invoiceIds,
      'matchedInvoiceNumber': invoiceNumber,
      'matchedInvoiceClientName': clientName,
      if (total is num) 'matchedInvoiceAmount': total,
      'matchedInvoiceAmountFormatted': totalFormatted,
      'linkStatus': item['linkStatus']?.toString().trim().isNotEmpty == true
          ? item['linkStatus']
          : 'linked',
      'linkStatusLabel':
          item['linkStatusLabel']?.toString().trim().isNotEmpty == true
              ? item['linkStatusLabel']
              : (isEs ? 'Vinculado' : 'Linked'),
      'hasExistingInvoiceLink': true,
      'alreadyLinked': item['alreadyLinked'] == true,
      'existingLinkedInvoiceIds': invoiceIds,
      'invoiceIds': invoiceIds,
      'invoiceNumbers': invoiceNumbers,
      'invoiceNumber': invoiceNumber,
      'invoice_number': invoiceNumber,
      if (clientName.isNotEmpty) 'clientName': clientName,
      if (clientName.isNotEmpty) 'counterpartyName': clientName,
    };
  }

  @override
  List<Map<String, dynamic>> bulkLinkableRowsFrom(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.where((row) {
      if (rowHasExistingInvoiceLink(row)) return false;
      if (rowEntryId(row) == null) return false;
      return linkedInvoiceIdsFromRow(row).isNotEmpty;
    }).toList(growable: false);
  }

  @override
  Future<void> linkAllSuggestedInvoices(
    ChatMessage message,
    List<Map<String, dynamic>> rows,
    bool isEs,
  ) async {
    final candidates = bulkLinkableRowsFrom(rows);
    if (candidates.isEmpty || bulkLinkingInvoices) return;
    setState(() => bulkLinkingInvoices = true);
    try {
      setState(() => bulkLinkErrors.clear());
      final links = [
        for (final row in candidates)
          {
            'entryId': rowEntryId(row),
            'invoiceIds': linkedInvoiceIdsFromRow(row),
          },
      ];
      final response = await StatementsApi().bulkLinkEntryInvoices(
        links: links,
      );
      final entries = response['entries'];
      var linked = 0;
      final patchesByEntryId = <String, Map<String, dynamic>>{};
      if (entries is List) {
        for (final raw in entries) {
          final item = safeMap(raw);
          if (item == null) continue;
          final entryId = item['entryId']?.toString().trim() ??
              safeMap(item['entry'])?['id']?.toString().trim() ??
              safeMap(item['entry'])?['_id']?.toString().trim() ??
              '';
          if (entryId.isEmpty) continue;
          patchesByEntryId[entryId] = linkedRowPatchFromBulkResponse(
            item,
            isEs,
          );
          linked += 1;
        }
      }
      await runtime.updateTableRows(
        message: message,
        patchesByEntryId: patchesByEntryId,
      );

      final failed = response['failed'];
      final nextErrors = <String, String>{};
      if (failed is List) {
        for (final raw in failed) {
          final item = safeMap(raw);
          if (item == null) continue;
          final entryId = item['entryId']?.toString().trim() ?? '';
          if (entryId.isEmpty) continue;
          nextErrors[entryId] = item['message']?.toString().trim() ??
              (isEs ? 'No se pudo vincular' : 'Could not link');
        }
      }
      if (mounted) {
        setState(() {
          bulkLinkErrors
            ..clear()
            ..addAll(nextErrors);
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextErrors.isEmpty
                ? (isEs
                    ? 'Se vincularon $linked factura(s).'
                    : 'Linked $linked invoice(s).')
                : (isEs
                    ? 'Se vincularon $linked factura(s). ${nextErrors.length} fallaron.'
                    : 'Linked $linked invoice(s). ${nextErrors.length} failed.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => bulkLinkingInvoices = false);
      }
    }
  }

}
