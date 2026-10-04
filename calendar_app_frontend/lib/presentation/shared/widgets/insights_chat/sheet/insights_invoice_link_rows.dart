import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_shared.dart';
import 'package:hexora/theme/typography/typography_extension.dart';

import '../insights_chat_message.dart';
import '../insights_pending_invoice_link_edit.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsInvoiceLinkRows on InsightsChatSheetStateBase {
  @override
  String tableCellValue(
    Map<String, dynamic> row,
    Map<String, dynamic> column,
  ) {
    final key = column['key']?.toString() ?? '';
    if (!rowHasExistingInvoiceLink(row)) {
      return row[key]?.toString() ?? '';
    }

    final label = (column['label']?.toString() ?? '').trim().toLowerCase();
    final normalizedLabel =
        label.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i');

    if (key == 'matchedInvoiceNumber' ||
        key == 'invoiceNumber' ||
        key == 'invoice_number' ||
        normalizedLabel == 'factura') {
      return row['matchedInvoiceNumber']?.toString() ?? '';
    }

    if (key == 'matchedInvoiceClientName' ||
        key == 'invoiceClientName' ||
        key == 'clientInvoiceName' ||
        normalizedLabel == 'cliente factura') {
      return row['matchedInvoiceClientName']?.toString() ?? '';
    }

    if (key == 'matchedInvoiceAmountFormatted' ||
        key == 'invoiceAmountFormatted' ||
        key == 'invoiceAmount' ||
        normalizedLabel == 'importe factura') {
      return row['matchedInvoiceAmountFormatted']?.toString() ?? '';
    }

    if (key == 'linkStatusLabel') {
      return row['linkStatusLabel']?.toString() ?? '';
    }

    return row[key]?.toString() ?? '';
  }

  @override
  String? rowEntryId(Map<String, dynamic> row) {
    for (final key in const ['id', '_id', 'entryId', 'entry_id']) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  @override
  Map<String, dynamic> rowWithPendingLink(
    ChatMessage message,
    Map<String, dynamic> row,
  ) {
    final invoiceId = invoiceIdFromInsightsInvoiceRow(row);
    if (invoiceId.isNotEmpty) {
      final invoicePatch = pendingInsightsInvoiceRowPatches[
          '${messageKeyFor(message)}::$invoiceId'];
      if (invoicePatch != null) {
        row = <String, dynamic>{...row, ...invoicePatch};
      }
    }
    final entryId = rowEntryId(row);
    if (entryId == null) return row;
    final key = invoiceLinkKey(messageKeyFor(message), entryId);
    final pending = pendingInvoiceLinkEdits[key];
    if (pending == null) return row;
    final next = Map<String, dynamic>.from(row);
    next['matchedInvoiceId'] = pending.invoiceId;
    next['matchedInvoiceIds'] = <String>[pending.invoiceId];
    next['matchedInvoiceNumber'] = pending.invoiceNumber;
    next['matchedInvoiceClientName'] = pending.clientName;
    next['matchedInvoiceAmount'] = pending.total;
    next['matchedInvoiceAmountFormatted'] = pending.totalFormatted;
    next['hasExistingInvoiceLink'] = true;
    next['linkStatus'] = 'pending';
    next['linkStatusLabel'] = pending.pendingStatusLabel;
    next['existingLinkedInvoiceIds'] = <String>[pending.invoiceId];
    return next;
  }

  @override
  Map<String, dynamic> statementEntryFromInsightsRow(
    Map<String, dynamic> row,
  ) {
    final entryId = rowEntryId(row) ?? '';
    final invoiceIds = <String>{
      for (final invoice in linkedIncomeReviewInvoices(row))
        if (((invoice['invoiceId'] ?? invoice['id'])?.toString().trim() ?? '')
            .isNotEmpty)
          (invoice['invoiceId'] ?? invoice['id']).toString().trim(),
      for (final key in const [
        'matchedInvoiceIds',
        'existingLinkedInvoiceIds',
        'existingLinkedInvoices',
        'linkedInvoiceIds',
        'invoiceIds',
      ])
        if (row[key] is List)
          for (final item in row[key] as List)
            if ((item?.toString().trim() ?? '').isNotEmpty)
              item.toString().trim(),
      for (final key in const [
        'matchedInvoiceId',
        'existingLinkedInvoiceId',
        'linkedInvoiceId',
        'invoiceId',
        'invoice_id',
      ])
        if ((row[key]?.toString().trim() ?? '').isNotEmpty)
          row[key].toString().trim(),
    }.toList(growable: false);
    final invoiceNumber = (row['matchedInvoiceNumber'] ??
            row['invoiceNumber'] ??
            row['invoice_number'])
        ?.toString()
        .trim();
    final invoiceNumbers = invoiceNumber == null || invoiceNumber.isEmpty
        ? const <String>[]
        : invoiceNumber
            .split(RegExp(r'\s*\+\s*'))
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
    final clientId = (row['matchedInvoiceClientId'] ??
            row['invoiceClientId'] ??
            row['clientId'] ??
            row['client_id'])
        ?.toString()
        .trim();
    final clientName = (row['matchedInvoiceClientName'] ??
            row['invoiceClientName'] ??
            row['clientName'] ??
            row['counterpartyName'])
        ?.toString()
        .trim();
    return <String, dynamic>{
      ...row,
      '_id': entryId,
      'id': entryId,
      'date': row['date'] ?? row['fecha'],
      'description': row['concept'] ?? row['concepto'] ?? row['description'],
      'amount': row['amount'] ?? row['importe'] ?? row['amountFormatted'],
      if (invoiceIds.isNotEmpty) 'invoiceIds': invoiceIds,
      if (invoiceIds.isNotEmpty) 'invoiceId': invoiceIds.first,
      if (invoiceIds.isNotEmpty) 'invoice_id': invoiceIds.first,
      if (invoiceNumbers.isNotEmpty) 'invoiceNumbers': invoiceNumbers,
      if ((invoiceNumber ?? '').isNotEmpty) 'invoiceNumber': invoiceNumber,
      if ((invoiceNumber ?? '').isNotEmpty) 'invoice_number': invoiceNumber,
      if ((clientId ?? '').isNotEmpty) 'clientId': clientId,
      if ((clientId ?? '').isNotEmpty) 'client_id': clientId,
      if ((clientName ?? '').isNotEmpty) 'clientName': clientName,
      if ((clientName ?? '').isNotEmpty) 'counterpartyName': clientName,
    };
  }

  @override
  PendingInvoiceLinkEdit? linkEditFromStatementEntry(
    Map<String, dynamic> entry,
    Map<String, dynamic> row,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final invoiceIds = stringList(entry['invoiceIds']);
    final invoiceId = invoiceIds.isNotEmpty
        ? invoiceIds.first
        : (entry['invoiceId'] ?? entry['invoice_id'])?.toString().trim() ?? '';
    if (invoiceId.isEmpty) return null;
    final invoiceNumbers = stringList(entry['invoiceNumbers']);
    final invoiceNumber = invoiceNumbers.isNotEmpty
        ? invoiceNumbers.join(' + ')
        : (entry['invoiceNumber'] ??
                    entry['invoice_number'] ??
                    row['matchedInvoiceNumber'])
                ?.toString()
                .trim() ??
            '';
    final clientName = (entry['clientName'] ??
                entry['counterpartyName'] ??
                row['matchedInvoiceClientName'])
            ?.toString()
            .trim() ??
        '';
    final totalFormatted =
        (row['matchedInvoiceAmountFormatted'] ?? row['invoiceAmountFormatted'])
                ?.toString()
                .trim() ??
            '';
    final displayParts = <String>[
      if (invoiceNumber.isNotEmpty) invoiceNumber,
      if (clientName.isNotEmpty) clientName,
    ];
    return PendingInvoiceLinkEdit(
      invoiceId: invoiceId,
      invoiceNumber: invoiceNumber,
      clientName: clientName,
      total: null,
      totalFormatted: totalFormatted,
      pendingStatusLabel: isEs ? 'Vinculado' : 'Linked',
      displayLabel: displayParts.isEmpty
          ? (isEs ? 'Factura vinculada' : 'Linked invoice')
          : displayParts.join(' · '),
    );
  }

  @override
  Map<String, dynamic> insightsRowPatchFromLinkedEntry(
    Map<String, dynamic> entry,
    PendingInvoiceLinkEdit edit,
    bool isEs,
  ) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final invoiceIds = stringList(entry['invoiceIds']);
    final invoiceNumbers = stringList(entry['invoiceNumbers']);
    final primaryId = invoiceIds.isNotEmpty ? invoiceIds.first : edit.invoiceId;
    final number = invoiceNumbers.isNotEmpty
        ? invoiceNumbers.join(' + ')
        : edit.invoiceNumber;
    final effectiveIds =
        invoiceIds.isNotEmpty ? invoiceIds : <String>[primaryId];
    final effectiveNumbers =
        invoiceNumbers.isNotEmpty ? invoiceNumbers : <String>[number];

    return <String, dynamic>{
      'matchedInvoiceId': primaryId,
      'matchedInvoiceIds': effectiveIds,
      'matchedInvoiceNumber': number,
      'matchedInvoiceClientName': edit.clientName,
      'matchedInvoiceAmount': edit.total,
      'matchedInvoiceAmountFormatted': edit.totalFormatted,
      'hasExistingInvoiceLink': true,
      'linkStatus': 'linked',
      'linkStatusLabel': isEs ? 'Vinculado' : 'Linked',
      'existingLinkedInvoiceIds': effectiveIds,
      'invoiceIds': effectiveIds,
      'invoiceNumbers': effectiveNumbers,
      'invoiceNumber': number,
      'invoice_number': number,
      if (edit.clientName.isNotEmpty) 'clientName': edit.clientName,
      if (edit.clientName.isNotEmpty) 'counterpartyName': edit.clientName,
    };
  }

  @override
  Future<Map<String, dynamic>> entryWithResolvedInvoiceIds(
    Map<String, dynamic> entry,
    Map<String, dynamic> row,
  ) async {
    final currentIds = entry['invoiceIds'];
    if (currentIds is List && currentIds.isNotEmpty) return entry;
    final rawNumbers = entry['invoiceNumbers'];
    final numbers = rawNumbers is List
        ? rawNumbers
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    if (numbers.isEmpty) return entry;

    final resolvedIds = <String>[];
    for (final number in numbers) {
      try {
        final matches = await invoicesApi.searchManualLinkCandidates(
          groupId: widget.groupId,
          q: number,
          status: 'issued',
          limit: 10,
        );
        final exact = matches.cast<Map<String, dynamic>?>().firstWhere(
              (candidate) =>
                  candidate?['invoiceNumber']?.toString().trim() == number,
              orElse: () => matches.isNotEmpty ? matches.first : null,
            );
        final id =
            (exact?['id'] ?? exact?['invoiceId'])?.toString().trim() ?? '';
        if (id.isNotEmpty) resolvedIds.add(id);
      } catch (_) {
        // The shared dialog can still open normally if lookup fails.
      }
    }
    if (resolvedIds.isEmpty) return entry;
    return <String, dynamic>{
      ...entry,
      'invoiceIds': resolvedIds,
      'invoiceId': resolvedIds.first,
      'invoice_id': resolvedIds.first,
    };
  }

  @override
  Map<String, dynamic> entryWithResolvedClientId(
    Map<String, dynamic> entry,
    List<Map<String, dynamic>> clients,
  ) {
    final existingClientId =
        (entry['clientId'] ?? entry['client_id'])?.toString().trim() ?? '';
    if (existingClientId.isNotEmpty) return entry;
    final targetName =
        (entry['clientName'] ?? entry['counterpartyName'])?.toString().trim() ??
            '';
    if (targetName.isEmpty) return entry;

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();

    final normalizedTarget = normalize(targetName);
    final match = clients.cast<Map<String, dynamic>?>().firstWhere(
      (client) {
        final id = client?['id']?.toString().trim() ?? '';
        final name = client?['name']?.toString().trim() ?? '';
        if (id.isEmpty || name.isEmpty) return false;
        final normalizedName = normalize(name);
        return normalizedName == normalizedTarget ||
            normalizedTarget.contains(normalizedName) ||
            normalizedName.contains(normalizedTarget);
      },
      orElse: () => null,
    );
    final clientId = match?['id']?.toString().trim() ?? '';
    if (clientId.isEmpty) return entry;
    return <String, dynamic>{
      ...entry,
      'clientId': clientId,
      'client_id': clientId,
    };
  }

  @override
  Future<void> pickInvoiceLinkForRow(
    ChatMessage message,
    Map<String, dynamic> row, {
    bool showSuggestions = false,
  }) async {
    final entryId = rowEntryId(row);
    if (entryId == null || runtime.sending) return;
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final stateKey = invoiceLinkKey(messageKeyFor(message), entryId);
    var entry = await entryWithResolvedInvoiceIds(
      statementEntryFromInsightsRow(row),
      row,
    );
    if (!mounted) return;
    final controller = StatementsController(groupId: widget.groupId)
      ..entries = <Map<String, dynamic>>[entry]
      ..allEntries = <Map<String, dynamic>>[entry];
    await controller.loadClients();
    entry = entryWithResolvedClientId(entry, controller.clients);
    controller
      ..entries = <Map<String, dynamic>>[entry]
      ..allEntries = <Map<String, dynamic>>[entry];
    if (!mounted) {
      controller.dispose();
      return;
    }
    if (showSuggestions) {
      await StatementsShared.showInvoiceSuggestionsDialog(
        context,
        controller,
        entry,
      );
    } else {
      await StatementsShared.showInvoiceLinkDialog(
        context,
        controller,
        entry,
        expenseOnly: false,
      );
    }
    final updated = (controller.entries.isNotEmpty
            ? controller.entries.first
            : controller.allEntries.isNotEmpty
                ? controller.allEntries.first
                : entry)
        .cast<String, dynamic>();
    controller.dispose();
    if (!mounted) return;
    final edit = linkEditFromStatementEntry(updated, row, isEs);
    if (edit == null) return;
    setState(() {
      pendingInvoiceLinkEdits[stateKey] = edit;
    });
    await runtime.updateTableRow(
      message: message,
      entryId: entryId,
      rowPatch: insightsRowPatchFromLinkedEntry(updated, edit, isEs),
    );
  }

  @override
  Widget buildInvoiceLinkStatusCell(
    BuildContext context, {
    required ChatMessage message,
    required Map<String, dynamic> row,
    required String value,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final entryId = rowEntryId(row);
    final canEdit = entryId != null;
    final messageKey = messageKeyFor(message);
    final stateKey =
        entryId == null ? '' : invoiceLinkKey(messageKey, entryId);
    final pending = entryId == null ? null : pendingInvoiceLinkEdits[stateKey];
    final bulkError = entryId == null ? null : bulkLinkErrors[entryId];
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final actionBackground =
        isDark ? cs.primary.withValues(alpha: 0.08) : const Color(0xFFEAF3FF);
    final actionBorder =
        isDark ? cs.primary.withValues(alpha: 0.18) : const Color(0xFFBDD3F0);
    final actionForeground = isDark ? cs.primary : const Color(0xFF245C99);
    final suggestLabel = isEs ? 'Sugerir' : 'Suggest';
    final editLabel = (row['hasExistingInvoiceLink'] == true ||
            (row['linkStatus']?.toString() == 'linked'))
        ? (isEs ? 'Editar vínculo' : 'Edit link')
        : (isEs ? 'Vincular' : 'Link');

    final tooltipText = pending?.displayLabel.trim().isNotEmpty == true
        ? pending!.displayLabel.trim()
        : value.trim();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canEdit) ...[
            Tooltip(
              message: isEs
                  ? 'Buscar coincidencias sugeridas'
                  : 'Find suggested matches',
              child: InkWell(
                onTap: () => pickInvoiceLinkForRow(
                  message,
                  row,
                  showSuggestions: true,
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: actionBorder),
                  ),
                  child: Text(
                    suggestLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: actionForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Tooltip(
              message: tooltipText.isEmpty ? editLabel : tooltipText,
              child: InkWell(
                onTap: () => pickInvoiceLinkForRow(message, row),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: actionBorder,
                    ),
                  ),
                  child: Text(
                    editLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption.copyWith(
                      color: actionForeground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (bulkError != null && bulkError.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: bulkError,
              child: Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: cs.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget buildUnlinkedIncomeLinkActionCell(
    BuildContext context, {
    required ChatMessage message,
    required Map<String, dynamic> row,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    if (!rowCanLinkUnlinkedIncomeInvoice(row)) {
      return Text(
        '-',
        style: t.caption.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return buildInvoiceLinkStatusCell(
      context,
      message: message,
      row: row,
      value: row['linkStatusLabel']?.toString() ?? '',
      cs: cs,
      t: t,
    );
  }

  @override
  Widget buildTransactionLinkedStateCell(
    Map<String, dynamic> row, {
    required ColorScheme cs,
    required AppTypography t,
    required bool isEs,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final linked = rowHasExistingInvoiceLink(row);
    final color = linked
        ? (isDark ? Colors.greenAccent : const Color(0xFF0F9F72))
        : (isDark ? cs.onSurfaceVariant : const Color(0xFF526173));
    final background = linked
        ? (isDark
            ? Colors.greenAccent.withValues(alpha: 0.16)
            : const Color(0xFFE5F8F1))
        : (isDark
            ? cs.onSurfaceVariant.withValues(alpha: 0.08)
            : const Color(0xFFF2F5F8));
    final border = linked
        ? (isDark
            ? Colors.greenAccent.withValues(alpha: 0.28)
            : const Color(0xFFAEE7D4))
        : (isDark
            ? cs.onSurfaceVariant.withValues(alpha: 0.16)
            : const Color(0xFFD5DCE5));
    final label = linked ? (isEs ? 'Sí' : 'Yes') : 'No';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            linked ? Icons.link_rounded : Icons.link_off_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: t.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

}
