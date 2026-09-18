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

mixin InsightsBankIncomeParsing on InsightsChatSheetStateBase {
  @override
  Map<String, dynamic>? linkInvoiceToEntryAction(Map<String, dynamic> row) {
    final actions = row['actions'];
    if (actions is List) {
      for (final raw in actions) {
        final action = safeMap(raw);
        if (action == null) continue;
        if (action['type']?.toString().trim() == 'link_invoice_to_entry') {
          return action;
        }
      }
    }
    final action = safeMap(row['action']);
    if (action?['type']?.toString().trim() == 'link_invoice_to_entry') {
      return action;
    }
    return null;
  }

  @override
  Map<String, dynamic>? bankIncomeSearchPayload(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return null;
    if (response['rows'] is List ||
        response['columns'] is List ||
        safeMap(response['table'])?['rows'] is List ||
        safeMap(response['table'])?['columns'] is List) {
      return response;
    }
    for (final key in const ['table', 'data', 'result', 'payload']) {
      final nested = safeMap(response[key]);
      final payload = bankIncomeSearchPayload(nested);
      if (payload != null) return payload;
    }
    return response;
  }

  @override
  List<Map<String, dynamic>> bankIncomeCandidateRowsFromResponse(
    Map<String, dynamic>? response,
  ) {
    final payload = bankIncomeSearchPayload(response);
    final table = safeMap(payload?['table']);
    final rows = table?['rows'] ?? payload?['rows'];
    if (rows is! List) return const <Map<String, dynamic>>[];
    return rows
        .map((item) => safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  List<Map<String, dynamic>> candidateColumnsFromTable(
    Map<String, dynamic>? table,
    List<Map<String, dynamic>> rows,
  ) {
    final columns = table?['columns'];
    if (columns is List) {
      final parsed = columns
          .map((item) => safeMap(item))
          .whereType<Map<String, dynamic>>()
          .where((column) {
        final key = column['key']?.toString() ?? '';
        return key.isNotEmpty &&
            key != 'actions' &&
            !isBankIncomeMatchMetadataKey(key);
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    final first = rows.isNotEmpty ? rows.first : const <String, dynamic>{};
    return first.keys
        .where((key) =>
            key != 'actions' &&
            !isBankIncomeMatchMetadataKey(key) &&
            safeMap(first[key]) == null)
        .take(6)
        .map((key) => {'key': key, 'label': key})
        .toList(growable: false);
  }

  @override
  bool isBankIncomeMatchMetadataKey(String key) {
    final normalized = key.trim().toLowerCase();
    return normalized.startsWith('match') || normalized == 'scoring';
  }

  @override
  List<Map<String, dynamic>> bankIncomeCandidateColumnsFromResponse(
    Map<String, dynamic>? response,
    List<Map<String, dynamic>> rows,
  ) {
    final payload = bankIncomeSearchPayload(response);
    final table = safeMap(payload?['table']);
    final columns = table?['columns'] ?? payload?['columns'];
    if (columns is List) {
      final parsed = columns
          .map((item) => safeMap(item))
          .whereType<Map<String, dynamic>>()
          .where((column) {
        final key = column['key']?.toString() ?? '';
        return key.isNotEmpty &&
            key != 'actions' &&
            !isBankIncomeMatchMetadataKey(key);
      }).toList(growable: false);
      if (parsed.isNotEmpty) return parsed;
    }
    return candidateColumnsFromTable(null, rows);
  }

  @override
  Map<String, dynamic>? bankIncomeScoringFromResponse(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return null;
    final direct = safeMap(response['scoring']);
    if (direct != null) return direct;
    for (final key in const ['data', 'result', 'payload', 'table']) {
      final nested = safeMap(response[key]);
      final scoring = bankIncomeScoringFromResponse(nested);
      if (scoring != null) return scoring;
    }
    return null;
  }

  @override
  Map<String, dynamic>? bankIncomeGroupMatchingFromResponse(
    Map<String, dynamic>? response,
  ) {
    if (response == null) return null;
    final direct = safeMap(response['groupMatching']);
    if (direct != null) return direct;
    for (final key in const ['data', 'result', 'payload', 'table']) {
      final nested = safeMap(response[key]);
      final policy = bankIncomeGroupMatchingFromResponse(nested);
      if (policy != null) return policy;
    }
    return null;
  }

  @override
  List<Map<String, dynamic>> bankIncomeMatchedInvoices(
    Map<String, dynamic> row,
  ) {
    final raw = row['matchedInvoices'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map(safeMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  int bankIncomeMatchedInvoiceCount(Map<String, dynamic> row) {
    final backendCount = row['matchedInvoiceCount'];
    if (backendCount is num && backendCount > 0) return backendCount.toInt();
    final invoices = bankIncomeMatchedInvoices(row);
    return invoices.isEmpty ? 1 : invoices.length;
  }

  @override
  bool isGroupedBankIncomeCandidate(Map<String, dynamic> row) {
    return row['isCombinedMatch'] == true ||
        row['matchMode']?.toString().trim().toLowerCase() == 'grouped' ||
        bankIncomeMatchedInvoiceCount(row) > 1;
  }

  @override
  String bankIncomeInvoiceCountLabel(
    Map<String, dynamic> row,
    bool isEs,
  ) {
    final count = bankIncomeMatchedInvoiceCount(row);
    if (isEs) return '$count ${count == 1 ? 'factura' : 'facturas'}';
    return '$count ${count == 1 ? 'invoice' : 'invoices'}';
  }

  @override
  bool bankIncomeMatchIsMedium(Map<String, dynamic> row) {
    final confidence = bankIncomeMatchConfidence(row).toLowerCase();
    return confidence == 'media' || confidence == 'medium';
  }

  @override
  String? bankIncomeCombinationLabel(
    Map<String, dynamic> row,
    bool isEs,
  ) {
    final unique = row['combinationUnique'];
    final rawCount = row['combinationMatchCount'];
    final count = rawCount is num ? rawCount.toInt() : null;
    if (unique == true && count == 1) {
      return isEs ? 'Combinación única' : 'Unique combination';
    }
    if (count != null && count > 1) {
      return isEs
          ? '$count combinaciones posibles'
          : '$count possible combinations';
    }
    return null;
  }

  @override
  List<Map<String, dynamic>> bankIncomeCombinationOptions(
    Map<String, dynamic> row,
  ) {
    final raw = row['combinationOptions'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .map(safeMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  String bankIncomeCombinationId(Map<String, dynamic> option) {
    return option['combinationId']?.toString().trim() ?? '';
  }

  @override
  String confidenceFromFormattedScore(dynamic value) {
    final formatted = value?.toString().trim() ?? '';
    if (formatted.isEmpty) return '';
    final parts = formatted.split('·');
    if (parts.length < 2) return '';
    final label = parts.last.trim();
    final normalized = label.toLowerCase();
    if (const ['alta', 'media', 'baja', 'high', 'medium', 'low']
        .contains(normalized)) {
      return label;
    }
    return '';
  }

  @override
  Map<String, dynamic> bankIncomeCandidateForCombination(
    Map<String, dynamic> candidate,
    Map<String, dynamic>? option,
  ) {
    if (option == null) return candidate;
    final invoices = option['invoices'] is List
        ? (option['invoices'] as List)
            .map(safeMap)
            .whereType<Map<String, dynamic>>()
            .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final scoreFormatted =
        (option['scoreFormatted'] ?? option['matchScoreFormatted'])
            ?.toString()
            .trim();
    final confidence =
        (option['matchConfidenceLabel'] ?? option['confidenceLabel'])
                ?.toString()
                .trim() ??
            confidenceFromFormattedScore(scoreFormatted);
    final action = safeMap(option['action']);
    final actions = option['actions'] is List
        ? option['actions'] as List
        : action == null
            ? const <dynamic>[]
            : <dynamic>[action];
    return <String, dynamic>{
      ...candidate,
      'selectedCombinationId': bankIncomeCombinationId(option),
      'matchScoreFormatted': scoreFormatted,
      'matchScorePercent':
          option['matchScorePercent'] ?? option['scorePercent'],
      'matchConfidenceLabel': confidence,
      'matchReason': option['reason'] ?? option['matchReason'],
      'matchComponents': option['matchComponents'] ??
          option['scoreComponents'] ??
          const <String, dynamic>{},
      'matchedInvoices': invoices,
      'matchedInvoiceCount': option['matchedInvoiceCount'] ??
          option['invoiceCount'] ??
          invoices.length,
      'matchedInvoicesTotalFormatted':
          option['totalFormatted'] ?? option['matchedInvoicesTotalFormatted'],
      'deltaFormatted': option['deltaFormatted'],
      'invoiceDateSpanDays': option['invoiceDateSpanDays'],
      'actions': actions,
      'action': action,
    };
  }

  @override
  bool bankIncomeCandidateHasScore(Map<String, dynamic> row) {
    return (row['matchScoreFormatted']?.toString().trim().isNotEmpty ??
            false) ||
        row['matchScorePercent'] is num ||
        row['matchScore'] is num;
  }

  @override
  String bankIncomeMatchConfidence(Map<String, dynamic> row) {
    return row['matchConfidenceLabel']?.toString().trim() ?? '';
  }

  @override
  bool bankIncomeMatchIsLow(Map<String, dynamic> row) {
    final confidence = bankIncomeMatchConfidence(row).toLowerCase();
    return confidence == 'baja' || confidence == 'low';
  }

  @override
  String formatBankIncomeMatchNumber(dynamic value) {
    final number = value is num ? value : num.tryParse(value?.toString() ?? '');
    if (number == null) return value?.toString().trim() ?? '';
    if (number == number.roundToDouble()) return number.toInt().toString();
    return number.toStringAsFixed(1);
  }

  @override
  String bankIncomeMatchScoreText(
    Map<String, dynamic> row,
    bool isEs,
  ) {
    final formatted = row['matchScoreFormatted']?.toString().trim() ?? '';
    if (formatted.isNotEmpty) return formatted;
    final percent = formatBankIncomeMatchNumber(row['matchScorePercent']);
    final confidence = bankIncomeMatchConfidence(row);
    if (percent.isNotEmpty && confidence.isNotEmpty) {
      return '$percent% · $confidence';
    }
    if (percent.isNotEmpty) return '$percent%';
    return isEs ? 'Sin puntuación' : 'No score';
  }

  @override
  Color bankIncomeMatchColor(
    ColorScheme cs,
    Map<String, dynamic> row,
  ) {
    final confidence = bankIncomeMatchConfidence(row).toLowerCase();
    if (confidence == 'alta' || confidence == 'high') {
      return const Color(0xFF087A55);
    }
    if (confidence == 'media' || confidence == 'medium') {
      return const Color(0xFFA65A00);
    }
    if (confidence == 'baja' || confidence == 'low') {
      return cs.brightness == Brightness.dark
          ? const Color(0xFFE0A39B)
          : const Color(0xFF8C514B);
    }
    return cs.onSurfaceVariant;
  }

  @override
  double bankIncomeCandidateColumnWidth(Map<String, dynamic> column) {
    final width = num.tryParse(column['width']?.toString() ?? '');
    if (width != null && width > 0) return width.clamp(96, 240).toDouble();
    final key = column['key']?.toString().toLowerCase() ?? '';
    final align = column['align']?.toString();
    if (align == 'right' || key.contains('amount') || key.contains('importe')) {
      return 132;
    }
    if (key.contains('date') || key.contains('fecha')) return 118;
    return 170;
  }

  @override
  bool isBankIncomeCandidateAmountColumn(Map<String, dynamic> column) {
    final key = column['key']?.toString().trim().toLowerCase() ?? '';
    final align = column['align']?.toString().trim().toLowerCase() ?? '';
    return align == 'right' ||
        key.contains('amount') ||
        key.contains('importe') ||
        key.contains('total');
  }

  @override
  String bankIncomeCandidateValue(
    Map<String, dynamic> row,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

}
