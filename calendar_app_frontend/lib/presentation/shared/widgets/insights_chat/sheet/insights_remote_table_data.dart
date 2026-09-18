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

mixin InsightsRemoteTableData on InsightsChatSheetStateBase {
  @override
  String messageKeyFor(ChatMessage message) {
    return '${message.isUser ? 'u' : 'a'}::${message.timestamp.toIso8601String()}';
  }

  @override
  Map<String, dynamic>? tableQueryForMessage(ChatMessage message) {
    final direct = safeMap(message.tableQuery);
    if ((direct?['endpoint']?.toString().trim().isNotEmpty ?? false)) {
      return direct;
    }
    final fromTable = safeMap(message.table?['tableQuery']);
    if ((fromTable?['endpoint']?.toString().trim().isNotEmpty ?? false)) {
      return fromTable;
    }
    return null;
  }

  @override
  bool messageUsesRemoteTableData(ChatMessage message) =>
      tableQueryForMessage(message) != null;

  @override
  InsightsRemoteTableState? remoteTableStateFor(ChatMessage message) {
    return remoteTableStates[messageKeyFor(message)];
  }

  @override
  Map<String, dynamic>? effectiveTableForMessage(ChatMessage message) {
    final remote = remoteTableStateFor(message);
    if (remote?.loadedOnce == true && remote?.table != null) {
      return remote!.table;
    }
    return message.table;
  }

  @override
  Map<String, dynamic>? tableFromDataResponse(Map<String, dynamic> response) {
    final direct = safeMap(response['table']);
    if (direct != null) return direct;
    final data = safeMap(response['data']);
    if (data != null) {
      final nested = safeMap(data['table']);
      if (nested != null) return nested;
      if (data['columns'] is List && data['rows'] is List) return data;
    }
    if (response['columns'] is List && response['rows'] is List) {
      return response;
    }
    return null;
  }

  @override
  Map<String, dynamic>? paginationFromDataResponse(
    Map<String, dynamic> response,
  ) {
    final direct = safeMap(response['pagination']);
    if (direct != null) return direct;
    final data = safeMap(response['data']);
    return safeMap(data?['pagination']);
  }

  @override
  Map<String, dynamic> tableDataRequestBody({
    required Map<String, dynamic> tableQuery,
    required int page,
    required int pageSize,
    InsightsDateRange? filter,
  }) {
    final body = tableQuery.map(
      (key, value) => MapEntry(key.toString(), value),
    )..removeWhere((key, _) {
        final normalized = key.trim().toLowerCase();
        return normalized == 'endpoint' || normalized == 'method';
      });
    body.addAll(<String, dynamic>{
      'groupId': widget.groupId.trim(),
      'page': page,
      'pageSize': pageSize,
    });
    if (filter != null) {
      body.addAll(<String, dynamic>{
        'filterDateFrom': formatInsightsApiDate(filter.normalizedFrom),
        'filterDateTo': formatInsightsApiDate(
          filter.normalizedInclusiveTo.add(const Duration(days: 1)),
        ),
      });
    }
    return body;
  }

  @override
  int initialRemoteTablePageSize(ChatMessage message) {
    final table = message.table;
    final directPageSize = readInt(table?['pageSize']);
    if (directPageSize != null && directPageSize > 0) {
      return directPageSize.clamp(1, 100).toInt();
    }
    final truncatedTo = readInt(table?['truncatedTo']);
    if (truncatedTo != null && truncatedTo > 0) {
      return truncatedTo.clamp(1, 100).toInt();
    }
    final previewRows = (table?['rows'] is List)
        ? (table!['rows'] as List)
            .where((row) => safeMap(row)?['isSummaryRow'] != true)
            .length
        : 0;
    if (previewRows > 0) return previewRows.clamp(1, 100).toInt();
    return 50;
  }

  @override
  Future<void> loadRemoteTableData(
    ChatMessage message, {
    int page = 1,
    int? pageSize,
    InsightsDateRange? filter,
  }) async {
    final tableQuery = tableQueryForMessage(message);
    if (tableQuery == null || widget.groupId.trim().isEmpty) return;
    final messageKey = messageKeyFor(message);
    final state = remoteTableStates.putIfAbsent(
      messageKey,
      () => InsightsRemoteTableState(
        pageSize: pageSize ?? initialRemoteTablePageSize(message),
      ),
    );
    final requestSerial = state.requestSerial + 1;
    final nextPageSize = pageSize ?? state.effectivePageSize;
    setState(() {
      state
        ..loading = true
        ..error = null
        ..requestSerial = requestSerial
        ..page = page
        ..pageSize = nextPageSize;
    });

    try {
      final response = await runtime.executeJsonAction(<String, dynamic>{
        'endpoint': tableQuery['endpoint']?.toString().trim() ?? '',
        'method': tableQuery['method']?.toString().trim().isNotEmpty == true
            ? tableQuery['method'].toString().trim()
            : 'POST',
        'body': tableDataRequestBody(
          tableQuery: tableQuery,
          page: page,
          pageSize: nextPageSize,
          filter: filter,
        ),
      });
      if (!mounted) return;
      final latest = remoteTableStates[messageKey];
      if (latest == null || latest.requestSerial != requestSerial) return;
      final table = tableFromDataResponse(response);
      final pagination = paginationFromDataResponse(response);
      setState(() {
        latest
          ..table = table ?? latest.table
          ..pagination = pagination
          ..loading = false
          ..error = null
          ..loadedOnce = table != null || latest.loadedOnce
          ..page = readInt(pagination?['page']) ?? page
          ..pageSize = readInt(pagination?['pageSize']) ?? nextPageSize;
      });
    } on InsightsApiException catch (e) {
      if (!mounted) return;
      final latest = remoteTableStates[messageKey];
      if (latest == null || latest.requestSerial != requestSerial) return;
      setState(() {
        latest
          ..loading = false
          ..error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      final latest = remoteTableStates[messageKey];
      if (latest == null || latest.requestSerial != requestSerial) return;
      setState(() {
        latest
          ..loading = false
          ..error = e.toString();
      });
    }
  }

  @override
  void ensureRemoteTableDataLoaded(ChatMessage message) {
    if (!messageUsesRemoteTableData(message)) return;
    final state = remoteTableStateFor(message);
    if (state?.loadedOnce == true || state?.loading == true) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final filter = tableDateFilterFor(message);
      unawaited(loadRemoteTableData(message, page: 1, filter: filter));
    });
  }

  @override
  Future<void> clearTableDateFilter(ChatMessage message) async {
    final messageKey = messageKeyFor(message);
    setState(() => tableDateFilters.remove(messageKey));
    if (messageUsesRemoteTableData(message)) {
      await loadRemoteTableData(message, page: 1);
    }
  }

  @override
  Future<void> applyTableDateFilter(
    ChatMessage message,
    InsightsDateRange range,
  ) async {
    final messageKey = messageKeyFor(message);
    setState(() => tableDateFilters[messageKey] = range);
    if (messageUsesRemoteTableData(message)) {
      await loadRemoteTableData(message, page: 1, filter: range);
    }
  }

  @override
  Future<void> changeRemoteTablePage(
    ChatMessage message,
    int page,
  ) async {
    final filter = tableDateFilterFor(message);
    await loadRemoteTableData(message, page: page, filter: filter);
  }

  @override
  Future<void> reloadRemoteTableForMessage(ChatMessage message) async {
    if (!messageUsesRemoteTableData(message)) return;
    final state = remoteTableStateFor(message);
    await loadRemoteTableData(
      message,
      page: state?.effectivePage ?? 1,
      pageSize: state?.effectivePageSize,
      filter: tableDateFilterFor(message),
    );
  }

}
