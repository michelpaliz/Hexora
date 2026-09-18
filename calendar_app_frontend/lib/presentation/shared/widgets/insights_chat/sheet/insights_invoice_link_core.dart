import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/service_catalog/service.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_shared.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/sections/invoice_editor_pdf.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/file_download_launcher.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/editor/widgets/pdf_preview/pdf_preview_launcher.dart'
    as pdf_launcher;
import 'package:hexora/presentation/shared/downloads/download_jobs_store.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/groups/event/domain/event_domain.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:hexora/services/invoicing/invoice_api.dart';
import 'package:hexora/services/service_catalog/service_api_client.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:provider/provider.dart';

import '../dialogs/insights_event_edit_dialog.dart';
import '../insights_action_tokens.dart';
import '../insights_chat_enums.dart';
import '../insights_chat_menu.dart';
import '../insights_chat_message.dart';
import '../insights_chat_runtime.dart';
import '../insights_chat_sheet.dart';
import '../insights_date_range.dart';
import '../insights_json_utils.dart';
import '../insights_markdown.dart';
import '../insights_pending_invoice_link_edit.dart';
import '../insights_remote_table_state.dart';
import '../widgets/insights_async_icon_button.dart';
import '../widgets/insights_chat_bubble.dart';
import 'insights_chat_sheet_base.dart';

mixin InsightsInvoiceLinkCore on InsightsChatSheetStateBase {
  @override
  String invoiceLinkKey(String messageKey, String entryId) =>
      '$messageKey::$entryId';

  @override
  bool messageSupportsManualInvoiceLink(ChatMessage message) {
    if (!messageHasStructuredTable(message)) return false;
    final columns = tableColumnsFromMessage(message);
    return columns.any(
      (column) => column['key']?.toString() == 'linkStatusLabel',
    );
  }

  @override
  List<Map<String, dynamic>> columnsWithTransactionLinkedState(
    List<Map<String, dynamic>> columns, {
    required bool isEs,
  }) {
    const stateKey = 'transactionLinkedStateLabel';
    if (columns.any((column) => column['key']?.toString() == stateKey)) {
      return columns;
    }

    final next = <Map<String, dynamic>>[];
    var inserted = false;
    for (final column in columns) {
      final key = column['key']?.toString();
      if (!inserted && key == 'linkStatusLabel') {
        next.add({
          'key': stateKey,
          'label': isEs ? 'Vinculada' : 'Linked',
        });
        inserted = true;
      }
      next.add(column);
    }
    if (!inserted) {
      next.add({
        'key': stateKey,
        'label': isEs ? 'Vinculada' : 'Linked',
      });
    }
    return next;
  }

  @override
  Map<String, dynamic>? rowBankIncomeSearchAction(Map<String, dynamic> row) {
    final action = safeMap(row['bankIncomeSearchAction']);
    if (action == null || action.isEmpty) return null;
    final endpoint = action['endpoint']?.toString().trim() ?? '';
    return endpoint.isEmpty ? null : action;
  }

  @override
  bool rowsHaveBankIncomeSearch(List<Map<String, dynamic>> rows) {
    return rows.any((row) => rowBankIncomeSearchAction(row) != null);
  }

  @override
  List<Map<String, dynamic>> columnsWithBankIncomeSearchAction(
    List<Map<String, dynamic>> columns, {
    required bool isEs,
  }) {
    const actionKey = '__bankIncomeSearchAction';
    if (columns.any((column) => column['key']?.toString() == actionKey)) {
      return columns;
    }
    return <Map<String, dynamic>>[
      ...columns,
      {
        'key': actionKey,
        'label': isEs ? 'Ingreso' : 'Income',
      },
    ];
  }

  @override
  List<Map<String, dynamic>> columnsWithUnlinkedIncomeLinkAction(
    List<Map<String, dynamic>> columns, {
    required bool isEs,
  }) {
    const actionKey = '__unlinkedIncomeLinkAction';
    if (columns.any((column) => column['key']?.toString() == actionKey)) {
      return columns;
    }
    return <Map<String, dynamic>>[
      ...columns,
      {
        'key': actionKey,
        'label': isEs ? 'Acciones' : 'Actions',
      },
    ];
  }

  @override
  bool messageLooksLikeUnlinkedIncome(ChatMessage message) {
    final table = message.table ?? const <String, dynamic>{};
    final parts = [
      message.text,
      message.displayText,
      message.sourceUserMessage,
      table['title'],
      table['label'],
      safeMap(table['summary'])?['label'],
    ];
    final text = normalizedInsightText(parts.whereType<Object>().join(' '));
    final mentionsIncome = text.contains('ingres') || text.contains('income');
    final mentionsUnlinked =
        text.contains('vincul') || text.contains('unlinked');
    return mentionsIncome && mentionsUnlinked;
  }

  @override
  bool rowIsPositiveStatementEntry(Map<String, dynamic> row) {
    final amountText = StatementsShared.entryText(
      row,
      const ['amount', 'importe', 'amountFormatted'],
    );
    final amount = StatementsFormatters.parseAmount(amountText);
    return amount != null && amount > 0;
  }

  @override
  bool rowCanLinkUnlinkedIncomeInvoice(Map<String, dynamic> row) {
    if (rowEntryId(row) == null) return false;
    if (rowHasExistingInvoiceLink(row)) return false;
    return rowIsPositiveStatementEntry(row);
  }

  @override
  String invoiceIdFromInsightsInvoiceRow(Map<String, dynamic> row) {
    for (final key in const [
      'invoiceId',
      'invoice_id',
      'id',
      '_id',
    ]) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    final ids = row['invoiceIds'];
    if (ids is List) {
      for (final item in ids) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }
    return '';
  }

  @override
  String normalizedInsightText(Object? value) {
    return (value?.toString() ?? '')
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  @override
  bool isInvoiceStatusColumn(Map<String, dynamic> column) {
    final key = normalizedInsightText(column['key']);
    final label = normalizedInsightText(column['label']);
    return key == 'estado' ||
        key == 'status' ||
        key == 'statuslabel' ||
        key == 'paymentstatus' ||
        label == 'estado' ||
        label == 'status';
  }

  @override
  bool rowIsUnlinkedInvoice(Map<String, dynamic> row) {
    if (rowHasExistingInvoiceLink(row)) return false;
    for (final key in const [
      'estado',
      'status',
      'statusLabel',
      'paymentStatus',
      'paymentStatusLabel',
      'linkStatus',
      'linkStatusLabel',
    ]) {
      final text = normalizedInsightText(row[key]);
      if (text.isEmpty) continue;
      if (text.contains('no vincul') ||
          text.contains('sin vincul') ||
          text.contains('unlinked') ||
          text.contains('not linked')) {
        return true;
      }
    }
    return false;
  }

  @override
  bool rowHasExistingInvoiceLink(Map<String, dynamic> row) {
    if (row['hasExistingInvoiceLink'] == true) return true;
    for (final key in const [
      'linkStatus',
      'linkStatusLabel',
      'estado',
      'status',
      'statusLabel',
      'paymentStatus',
      'paymentStatusLabel',
    ]) {
      final status = normalizedInsightText(row[key]);
      if (status == 'linked' ||
          status == 'vinculado' ||
          status == 'paid' ||
          status == 'pagada' ||
          status.contains('vinculado') ||
          status.contains('linked')) {
        return true;
      }
    }
    final ids = row['existingLinkedInvoiceIds'];
    if (ids is List &&
        ids.where((id) => id.toString().trim().isNotEmpty).isNotEmpty) {
      return true;
    }
    final id = row['existingLinkedInvoiceId']?.toString().trim() ?? '';
    return id.isNotEmpty;
  }

  @override
  Map<String, dynamic> linkedInvoiceRowPatch({
    required Map<String, dynamic> invoiceRow,
    required Map<String, dynamic> incomeRow,
    required bool isEs,
  }) {
    final entryId = rowEntryId(incomeRow);
    final amountFormatted = (incomeRow['amountFormatted'] ??
                incomeRow['importeFormatted'] ??
                incomeRow['amount'] ??
                incomeRow['importe'])
            ?.toString()
            .trim() ??
        '';
    final date = (incomeRow['date'] ??
                incomeRow['fecha'] ??
                incomeRow['bookingDate'] ??
                incomeRow['booking_date'])
            ?.toString()
            .trim() ??
        '';
    final concept = (incomeRow['description'] ??
                incomeRow['concept'] ??
                incomeRow['concepto'])
            ?.toString()
            .trim() ??
        '';
    return <String, dynamic>{
      'hasExistingInvoiceLink': true,
      'linkStatus': 'linked',
      'linkStatusLabel': isEs ? 'Vinculada/pagada' : 'Linked/paid',
      'estado': isEs ? 'Vinculada/pagada' : 'Linked/paid',
      'status': 'linked',
      'statusLabel': isEs ? 'Vinculada/pagada' : 'Linked/paid',
      'paymentStatus': 'paid',
      'paymentStatusLabel': isEs ? 'Pagada' : 'Paid',
      if (entryId != null) 'linkedEntryId': entryId,
      if (entryId != null) 'bankEntryId': entryId,
      if (amountFormatted.isNotEmpty) 'paymentAmountFormatted': amountFormatted,
      if (amountFormatted.isNotEmpty) 'importePago': amountFormatted,
      if (date.isNotEmpty) 'paymentDate': date,
      if (date.isNotEmpty) 'fechaPago': date,
      if (concept.isNotEmpty) 'paymentConcept': concept,
      if (concept.isNotEmpty) 'conceptoPago': concept,
    };
  }

  @override
  List<String> linkedInvoiceIdsFromRow(Map<String, dynamic> row) {
    final ids = <String>{
      for (final key in const [
        'existingLinkedInvoiceIds',
        'matchedInvoiceIds',
        'linkedInvoiceIds',
        'invoiceIds',
      ])
        if (row[key] is List)
          for (final item in row[key] as List)
            if ((item?.toString().trim() ?? '').isNotEmpty)
              item.toString().trim(),
      for (final key in const [
        'existingLinkedInvoiceId',
        'matchedInvoiceId',
        'linkedInvoiceId',
        'invoiceId',
        'invoice_id',
      ])
        if ((row[key]?.toString().trim() ?? '').isNotEmpty)
          row[key].toString().trim(),
    }.toList(growable: false);
    return ids;
  }

  @override
  bool linkedRowNeedsInvoiceDisplayHydration(Map<String, dynamic> row) {
    if (!rowHasExistingInvoiceLink(row)) return false;
    if (linkedInvoiceIdsFromRow(row).isEmpty) return false;
    final number = row['matchedInvoiceNumber']?.toString().trim() ?? '';
    final client = row['matchedInvoiceClientName']?.toString().trim() ?? '';
    final amount =
        row['matchedInvoiceAmountFormatted']?.toString().trim() ?? '';
    return number.isEmpty || client.isEmpty || amount.isEmpty;
  }

}
