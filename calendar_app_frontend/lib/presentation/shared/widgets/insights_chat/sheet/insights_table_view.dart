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

mixin InsightsTableView on InsightsChatSheetStateBase {
  @override
  List<Map<String, dynamic>> tableColumnsFromMessage(ChatMessage message) {
    final columns = effectiveTableForMessage(message)?['columns'];
    if (columns is! List) return const [];
    return columns
        .map((item) => safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  List<Map<String, dynamic>> tableRowsFromMessage(ChatMessage message) {
    final rows = effectiveTableForMessage(message)?['rows'];
    if (rows is! List) return const [];
    return rows
        .map((item) => safeMap(item))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  @override
  Map<String, dynamic>? tableSummaryFromMessage(ChatMessage message) {
    return safeMap(effectiveTableForMessage(message)?['summary']);
  }

  @override
  InsightsDateRange? tableDateFilterFor(ChatMessage message) {
    return tableDateFilters[messageKeyFor(message)];
  }

  @override
  DateTime? parseInsightsTableDate(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return DateTime(parsed.year, parsed.month, parsed.day);
    }
    final match =
        RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})$').firstMatch(raw);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final rawYear = int.tryParse(match.group(3)!);
    if (day == null || month == null || rawYear == null) return null;
    final year = rawYear < 100 ? 2000 + rawYear : rawYear;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  @override
  String? tableDateColumnKey(List<Map<String, dynamic>> columns) {
    const preferredKeys = [
      'date',
      'fecha',
      'bookingDate',
      'booking_date',
      'valueDate',
      'value_date',
      'transactionDate',
      'transaction_date',
      'issueDate',
      'issue_date',
      'invoiceDate',
      'invoice_date',
      'createdAt',
      'created_at',
    ];
    for (final preferred in preferredKeys) {
      for (final column in columns) {
        final key = column['key']?.toString().trim() ?? '';
        if (key == preferred) return key;
      }
    }
    for (final column in columns) {
      final key = column['key']?.toString().trim() ?? '';
      final label = (column['label']?.toString() ?? '').trim().toLowerCase();
      if (key.toLowerCase().contains('date') ||
          label == 'fecha' ||
          label.contains('date')) {
        return key;
      }
    }
    return null;
  }

  @override
  DateTime? tableRowDate(
    Map<String, dynamic> row, {
    String? dateColumnKey,
  }) {
    if (dateColumnKey != null && dateColumnKey.isNotEmpty) {
      final parsed = parseInsightsTableDate(row[dateColumnKey]);
      if (parsed != null) return parsed;
    }
    for (final key in const [
      'date',
      'fecha',
      'bookingDate',
      'booking_date',
      'valueDate',
      'value_date',
      'transactionDate',
      'transaction_date',
      'issueDate',
      'issue_date',
      'invoiceDate',
      'invoice_date',
      'createdAt',
      'created_at',
    ]) {
      final parsed = parseInsightsTableDate(row[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  @override
  bool tableRowMatchesDateFilter(
    Map<String, dynamic> row,
    InsightsDateRange? filter,
    String? dateColumnKey,
  ) {
    if (filter == null) return true;
    final date = tableRowDate(row, dateColumnKey: dateColumnKey);
    if (date == null) return false;
    return !date.isBefore(filter.normalizedFrom) &&
        !date.isAfter(filter.normalizedInclusiveTo);
  }

  @override
  List<Map<String, dynamic>> filteredTableDataRowsForMessage(
    ChatMessage message,
  ) {
    if (messageUsesRemoteTableData(message)) {
      return tableRowsFromMessage(message)
          .where((row) => row['isSummaryRow'] != true)
          .toList(growable: false);
    }
    final filter = tableDateFilterFor(message);
    final dateColumnKey =
        tableDateColumnKey(tableColumnsFromMessage(message));
    return tableRowsFromMessage(message)
        .where((row) => row['isSummaryRow'] != true)
        .where((row) => tableRowMatchesDateFilter(row, filter, dateColumnKey))
        .toList(growable: false);
  }

  @override
  num? tableRowAmount(
    Map<String, dynamic> row, {
    String? amountColumnKey,
  }) {
    for (final value in [
      if (amountColumnKey != null && amountColumnKey.isNotEmpty)
        row[amountColumnKey],
      row['amount'],
      row['importe'],
      row['amountFormatted'],
      row['importeFormatted'],
    ]) {
      final parsed = StatementsFormatters.parseAmount(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  @override
  String formatInsightsTableTotal(
    BuildContext context,
    num total, {
    String fallbackCurrency = 'EUR',
  }) {
    final formatted = StatementsFormatters.formatAmount(context, total);
    final currency = fallbackCurrency.trim().isEmpty ? 'EUR' : fallbackCurrency;
    return '$formatted $currency';
  }

  @override
  String? currencyFromFormattedAmount(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final suffix =
        RegExp(r'\s([A-Z]{3}|€|\$|£)$').firstMatch(raw)?.group(1)?.trim();
    if (suffix != null && suffix.isNotEmpty) return suffix;
    final prefix = RegExp(r'^(€|\$|£)\s?').firstMatch(raw)?.group(1)?.trim();
    if (prefix != null && prefix.isNotEmpty) return prefix;
    return null;
  }

  @override
  Widget compactDateRangePickerShell(
    BuildContext pickerContext,
    Widget? child,
  ) {
    final media = MediaQuery.of(pickerContext);
    final availableWidth = media.size.width - 32;
    final availableHeight = media.size.height - 32;
    final maxWidth = availableWidth < 520 ? availableWidth : 520.0;
    final maxHeight = availableHeight < 620 ? availableHeight : 620.0;
    final theme = Theme.of(pickerContext);

    return Theme(
      data: theme.copyWith(
        datePickerTheme: theme.datePickerTheme.copyWith(
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Material(
              type: MaterialType.transparency,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<void> showTableDateFilterDialog(ChatMessage message) async {
    final isEs = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('es');
    final current = tableDateFilterFor(message);
    final dateColumnKey =
        tableDateColumnKey(tableColumnsFromMessage(message));
    final rowDates = tableRowsFromMessage(message)
        .where((row) => row['isSummaryRow'] != true)
        .map((row) => tableRowDate(row, dateColumnKey: dateColumnKey))
        .whereType<DateTime>()
        .toList(growable: false);
    final now = DateTime.now();
    rowDates.sort();
    final firstDate =
        rowDates.isNotEmpty ? rowDates.first : DateTime(now.year - 1);
    final lastDate =
        rowDates.isNotEmpty ? rowDates.last : DateTime(now.year + 1);
    Future<void> applyRange(InsightsDateRange range) async {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
      await applyTableDateFilter(message, range);
    }

    Future<void> pickCustomRange() async {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      final initialStart = current?.normalizedFrom ?? firstDate;
      final initialEnd = current?.normalizedInclusiveTo ?? lastDate;
      final picked = await showDateRangePicker(
        context: context,
        firstDate: firstDate,
        lastDate: lastDate,
        initialDateRange: DateTimeRange(
          start: initialStart.isBefore(firstDate) ? firstDate : initialStart,
          end: initialEnd.isAfter(lastDate) ? lastDate : initialEnd,
        ),
        helpText: isEs ? 'Filtrar fechas de la tabla' : 'Filter table dates',
        builder: compactDateRangePickerShell,
      );
      if (picked == null || !mounted) return;
      rootNavigator.maybePop();
      await applyTableDateFilter(
        message,
        InsightsDateRange(
          from: picked.start,
          inclusiveTo: picked.end,
        ),
      );
    }

    Widget presetButton({
      required String label,
      required IconData icon,
      required InsightsDateRange range,
    }) {
      final selected = range.sameRange(current);
      return Tooltip(
        message: label,
        child: ActionChip(
          avatar: Icon(icon, size: 15),
          label: Text(label),
          onPressed: () => applyRange(range),
          visualDensity: VisualDensity.compact,
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.14)
              : null,
        ),
      );
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEs ? 'Filtrar fechas' : 'Filter dates'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              presetButton(
                label: isEs ? 'Hoy' : 'Today',
                icon: Icons.today_rounded,
                range: insightsRangeForPreset('today'),
              ),
              presetButton(
                label: isEs ? 'Esta semana' : 'This week',
                icon: Icons.view_week_rounded,
                range: insightsRangeForPreset('week'),
              ),
              presetButton(
                label: isEs ? 'Este mes' : 'This month',
                icon: Icons.calendar_view_month_rounded,
                range: insightsRangeForPreset('month'),
              ),
              presetButton(
                label: isEs ? 'Mes pasado' : 'Last month',
                icon: Icons.history_rounded,
                range: insightsRangeForPreset('lastMonth'),
              ),
              Tooltip(
                message: isEs ? 'Rango personalizado' : 'Custom range',
                child: ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 15),
                  label: Text(isEs ? 'Personalizado' : 'Custom'),
                  onPressed: pickCustomRange,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(isEs ? 'Cancelar' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildInsightsTableView(
    BuildContext context, {
    required ChatMessage message,
    required ColorScheme cs,
    required AppTypography t,
  }) {
    final tableScrollController = tableScrollControllers.putIfAbsent(
      messageKeyFor(message),
      () => ScrollController(),
    );
    final l = AppLocalizations.of(context)!;
    final isEs = l.localeName.toLowerCase().startsWith('es');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remoteTable = remoteTableStateFor(message);
    final usesRemoteTable = messageUsesRemoteTableData(message);
    final linkedIncomeReview = messageIsLinkedIncomeReview(message);
    final linkedIncomeReviewLoading =
        linkedIncomeReview && message.table?['loading'] == true;
    final linkedIncomeReviewError = linkedIncomeReview
        ? (message.table?['loadError']?.toString().trim())
        : null;
    final baseColumns = tableColumnsFromMessage(message);
    final rows = tableRowsFromMessage(message)
        .map((row) => rowWithPendingLink(message, row))
        .toList(growable: false);
    final supportsManualLinking = messageSupportsManualInvoiceLink(message);
    final hasEditableLinkRows = rows.any((row) => rowEntryId(row) != null);
    final hasManualLinking = supportsManualLinking && hasEditableLinkRows;
    final columnsWithLinkedState = supportsManualLinking
        ? columnsWithTransactionLinkedState(baseColumns, isEs: isEs)
        : baseColumns;
    final columns = hasManualLinking
        ? columnsWithLinkedState
        : columnsWithLinkedState
            .where((column) => column['key']?.toString() != 'linkStatusLabel')
            .toList(growable: false);
    final summary = tableSummaryFromMessage(message);
    final allDataRows = rows
        .where((row) => row['isSummaryRow'] != true)
        .toList(growable: false);
    final tableFilter = tableDateFilterFor(message);
    final dateColumnKey = tableDateColumnKey(columns);
    final dataRows = usesRemoteTable
        ? allDataRows
        : allDataRows
            .where((row) =>
                tableRowMatchesDateFilter(row, tableFilter, dateColumnKey))
            .toList(growable: false);
    final tableFilterActive = tableFilter != null;
    final hasBankIncomeSearch = rowsHaveBankIncomeSearch(dataRows);
    final hasUnlinkedIncomeLinkActions = !hasManualLinking &&
        (messageLooksLikeUnlinkedIncome(message) ||
            dataRows.any(rowIsUnlinkedInvoice)) &&
        dataRows.any(rowCanLinkUnlinkedIncomeInvoice);
    final columnsWithBankIncomeSearch = hasBankIncomeSearch
        ? columnsWithBankIncomeSearchAction(columns, isEs: isEs)
        : columns;
    final displayedColumns = hasUnlinkedIncomeLinkActions
        ? columnsWithUnlinkedIncomeLinkAction(
            columnsWithBankIncomeSearch,
            isEs: isEs,
          )
        : columnsWithBankIncomeSearch;
    final bulkLinkableRows = hasManualLinking
        ? bulkLinkableRowsFrom(dataRows)
        : const <Map<String, dynamic>>[];
    if (hasManualLinking) {
      unawaited(hydrateLinkedInvoiceDisplayFields(message, dataRows, isEs));
    }
    final summaryRow = rows.cast<Map<String, dynamic>?>().firstWhere(
          (row) => row?['isSummaryRow'] == true,
          orElse: () => null,
        );
    final effectiveTable = effectiveTableForMessage(message);
    final hasMore = usesRemoteTable
        ? ((remoteTable?.totalPages ?? 1) > 1)
        : message.table?['hasMore'] == true;
    final truncatedTo = effectiveTable?['truncatedTo'];
    final totalAvailable = usesRemoteTable
        ? remoteTable?.totalRows
        : effectiveTable?['totalAvailable'];
    final summaryLabel = summary?['label']?.toString().trim().isNotEmpty == true
        ? summary!['label'].toString().trim()
        : (summaryRow?['label']?.toString().trim().isNotEmpty == true
            ? summaryRow!['label'].toString().trim()
            : null);
    final rightAlignedColumnKey = displayedColumns.reversed
        .firstWhere(
          (column) => column['align']?.toString() == 'right',
          orElse: () => const <String, dynamic>{},
        )['key']
        ?.toString();
    final rawSummaryAmount =
        summary?['amountFormatted']?.toString().trim().isNotEmpty == true
            ? summary!['amountFormatted'].toString().trim()
            : ((rightAlignedColumnKey != null &&
                    rightAlignedColumnKey.isNotEmpty &&
                    summaryRow?[rightAlignedColumnKey]
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true)
                ? summaryRow![rightAlignedColumnKey].toString().trim()
                : '');
    final filteredTotal = tableFilterActive && !usesRemoteTable
        ? dataRows
            .map((row) => tableRowAmount(
                  row,
                  amountColumnKey: rightAlignedColumnKey,
                ))
            .whereType<num>()
            .fold<num>(0, (sum, amount) => sum + amount)
        : null;
    final summaryAmount = filteredTotal == null
        ? rawSummaryAmount
        : formatInsightsTableTotal(
            context,
            filteredTotal,
            fallbackCurrency:
                currencyFromFormattedAmount(rawSummaryAmount) ?? 'EUR',
          );

    const lightHeaderBackground = Color(0xFFEAF2FF);
    const lightHeaderForeground = Color(0xFF24364B);
    const lightTableBorder = Color(0xFFDCE4F0);
    const lightRowEven = Color(0xFFFFFFFF);
    const lightRowOdd = Color(0xFFF8FAFD);
    const lightRowHover = Color(0xFFF1F6FF);
    const lightUnlinkedRow = Color(0xFFFFFBF3);
    final reviewWarning =
        isDark ? const Color(0xFFFFB45B) : const Color(0xFF9A5B00);

    final headerStyle = t.bodySmall.copyWith(
      color: isDark ? cs.onSurfaceVariant : lightHeaderForeground,
      fontWeight: FontWeight.w700,
      fontSize: 11.5,
    );
    final cellStyle = t.bodySmall.copyWith(
      color: isDark ? cs.onSurface : const Color(0xFF344052),
      fontWeight: FontWeight.w500,
      fontSize: 12,
      height: 1.15,
    );
    final hasSummaryBar = (summaryLabel != null && summaryLabel.isNotEmpty) ||
        summaryAmount.isNotEmpty;
    final remoteLoading = remoteTable?.loading == true;
    final tableLoading = remoteLoading || linkedIncomeReviewLoading;
    final remoteError = remoteTable?.error?.trim();
    final tableError = (linkedIncomeReviewError?.isNotEmpty ?? false)
        ? linkedIncomeReviewError
        : remoteError;
    final remoteTotalPages = remoteTable?.totalPages ?? 1;
    final remotePage = remoteTable?.effectivePage ?? 1;
    final remoteTotalRows = remoteTable?.loadedOnce == true
        ? remoteTable!.totalRows
        : dataRows.length;

    Widget buildBulkLinkButton({bool compact = false}) {
      if (compact) {
        return TextButton.icon(
          onPressed: bulkLinkingInvoices
              ? null
              : () => linkAllSuggestedInvoices(
                    message,
                    dataRows,
                    isEs,
                  ),
          icon: bulkLinkingInvoices
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : const Icon(Icons.link_rounded, size: 14),
          label: Text(
            isEs
                ? 'Vincular ${bulkLinkableRows.length} sugeridas'
                : 'Link ${bulkLinkableRows.length} suggested',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          style: TextButton.styleFrom(
            foregroundColor: cs.primary,
            minimumSize: const Size(0, 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: t.bodySmall.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      }

      return FilledButton.tonalIcon(
        onPressed: bulkLinkingInvoices
            ? null
            : () => linkAllSuggestedInvoices(
                  message,
                  dataRows,
                  isEs,
                ),
        icon: bulkLinkingInvoices
            ? SizedBox(
                width: compact ? 12 : 14,
                height: compact ? 12 : 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : Icon(Icons.link_rounded, size: compact ? 14 : 16),
        label: Text(
          isEs
              ? 'Vincular sugeridas (${bulkLinkableRows.length})'
              : 'Link suggested (${bulkLinkableRows.length})',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          minimumSize: compact ? const Size(0, 30) : null,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 16,
            vertical: compact ? 7 : 10,
          ),
          tapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          textStyle: t.bodySmall.copyWith(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    Widget buildPaginationControls() {
      if (!usesRemoteTable || remoteTotalPages <= 1) {
        return const SizedBox.shrink();
      }
      final canPrevious = remotePage > 1 && !remoteLoading;
      final canNext = remotePage < remoteTotalPages && !remoteLoading;
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            isEs
                ? 'Pagina $remotePage de $remoteTotalPages'
                : 'Page $remotePage of $remoteTotalPages',
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: isEs ? 'Pagina anterior' : 'Previous page',
            child: IconButton(
              onPressed: canPrevious
                  ? () => changeRemoteTablePage(message, remotePage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Tooltip(
            message: isEs ? 'Pagina siguiente' : 'Next page',
            child: IconButton(
              onPressed: canNext
                  ? () => changeRemoteTablePage(message, remotePage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      );
    }

    Widget buildSummaryTrailing() {
      return Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: isDark
              ? cs.surfaceContainerHighest.withValues(alpha: 0.42)
              : cs.surface.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.38),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bulkLinkableRows.isNotEmpty) buildBulkLinkButton(compact: true),
            if (bulkLinkableRows.isNotEmpty && summaryAmount.isNotEmpty)
              Container(
                width: 1,
                height: 20,
                color: cs.outlineVariant.withValues(alpha: 0.55),
              ),
            if (summaryAmount.isNotEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                child: Text(
                  summaryAmount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (linkedIncomeReview) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: reviewWarning.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: reviewWarning.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  size: 17,
                  color: reviewWarning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEs
                        ? 'Revisión requerida: coincidencia inferior al ${formatBankIncomeMatchNumber(message.table?['threshold'] ?? 60)}%'
                        : 'Review required: match below ${formatBankIncomeMatchNumber(message.table?['threshold'] ?? 60)}%',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (bulkLinkableRows.isNotEmpty && !hasSummaryBar) ...[
          Align(
            alignment: Alignment.centerRight,
            child: buildBulkLinkButton(),
          ),
          const SizedBox(height: 10),
        ],
        if (linkedIncomeReview && dataRows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
                  : lightRowEven,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? cs.outlineVariant.withValues(alpha: 0.28)
                    : lightTableBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (linkedIncomeReviewLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else
                  Icon(
                    linkedIncomeReviewError?.isNotEmpty == true
                        ? Icons.error_outline_rounded
                        : Icons.verified_outlined,
                    color: linkedIncomeReviewError?.isNotEmpty == true
                        ? cs.error
                        : cs.onSurfaceVariant,
                    size: 27,
                  ),
                const SizedBox(height: 10),
                Text(
                  linkedIncomeReviewLoading
                      ? (isEs ? 'Cargando revisión...' : 'Loading review...')
                      : linkedIncomeReviewError?.isNotEmpty == true
                          ? linkedIncomeReviewError!
                          : (isEs
                              ? 'No hay ingresos vinculados que requieran revisión.'
                              : 'There is no linked income requiring review.'),
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: linkedIncomeReviewError?.isNotEmpty == true
                        ? cs.error
                        : cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!linkedIncomeReviewLoading &&
                    linkedIncomeReviewError?.isNotEmpty == true) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => refreshLinkedIncomeReview(message),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(isEs ? 'Reintentar' : 'Retry'),
                  ),
                ],
              ],
            ),
          )
        else if (tableFilterActive && dataRows.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
                  : lightRowEven,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? cs.outlineVariant.withValues(alpha: 0.28)
                    : lightTableBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.filter_alt_off_rounded,
                  color: cs.onSurfaceVariant,
                  size: 26,
                ),
                const SizedBox(height: 10),
                Text(
                  isEs
                      ? 'No hay movimientos dentro del intervalo seleccionado.'
                      : 'No movements within the selected interval.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else if (linkedIncomeReview)
          buildLinkedIncomeReviewResults(
            context,
            message: message,
            rows: dataRows,
            cs: cs,
            t: t,
            isDark: isDark,
            isEs: isEs,
            loading: tableLoading,
          )
        else
          Stack(
            children: [
              Scrollbar(
                controller: tableScrollController,
                thumbVisibility: true,
                notificationPredicate: (notification) =>
                    notification.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: tableScrollController,
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 620),
                    decoration: BoxDecoration(
                      color: isDark
                          ? cs.surfaceContainerHighest.withValues(alpha: 0.16)
                          : lightRowEven,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? cs.outlineVariant.withValues(alpha: 0.28)
                            : lightTableBorder,
                      ),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: const Color(0xFF274060)
                                    .withValues(alpha: 0.06),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: DataTable(
                      headingRowHeight: 32,
                      dataRowMinHeight: linkedIncomeReview
                          ? 62
                          : (hasManualLinking || hasUnlinkedIncomeLinkActions)
                              ? 34
                              : 30,
                      dataRowMaxHeight: linkedIncomeReview
                          ? double.infinity
                          : (hasManualLinking || hasUnlinkedIncomeLinkActions)
                              ? 48
                              : 34,
                      horizontalMargin: 10,
                      columnSpacing: 14,
                      dividerThickness: 0.5,
                      headingRowColor: WidgetStateProperty.all(
                        isDark
                            ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
                            : lightHeaderBackground,
                      ),
                      headingTextStyle: headerStyle,
                      dataTextStyle: cellStyle,
                      columns: [
                        for (final column in displayedColumns)
                          DataColumn(
                            numeric: column['align']?.toString() == 'right',
                            label: Text(column['label']?.toString() ?? ''),
                          ),
                      ],
                      rows: [
                        for (final entry in dataRows.asMap().entries)
                          DataRow(
                            color: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.hovered)) {
                                return isDark
                                    ? cs.primary.withValues(alpha: 0.08)
                                    : lightRowHover;
                              }
                              if (rowIsUnlinkedInvoice(entry.value)) {
                                return isDark
                                    ? const Color(0xFFFFB020)
                                        .withValues(alpha: 0.075)
                                    : lightUnlinkedRow;
                              }
                              if (isDark) return null;
                              return entry.key.isEven
                                  ? lightRowEven
                                  : lightRowOdd;
                            }),
                            cells: [
                              for (final column in displayedColumns)
                                DataCell(
                                  linkedIncomeReview
                                      ? buildLinkedIncomeReviewTableCell(
                                          message,
                                          entry.value,
                                          column,
                                          cs: cs,
                                          t: t,
                                          isDark: isDark,
                                          isEs: isEs,
                                          cellStyle: cellStyle,
                                        )
                                      : Tooltip(
                                          message: tableCellValue(
                                              entry.value, column),
                                          waitDuration:
                                              const Duration(milliseconds: 350),
                                          child: column['key']?.toString() ==
                                                  '__bankIncomeSearchAction'
                                              ? buildBankIncomeSearchCell(
                                                  context,
                                                  message: message,
                                                  row: entry.value,
                                                  cs: cs,
                                                  t: t,
                                                  isEs: isEs,
                                                )
                                              : column['key']?.toString() ==
                                                      '__unlinkedIncomeLinkAction'
                                                  ? buildUnlinkedIncomeLinkActionCell(
                                                      context,
                                                      message: message,
                                                      row: entry.value,
                                                      cs: cs,
                                                      t: t,
                                                    )
                                                  : column['key']?.toString() ==
                                                          'linkStatusLabel'
                                                      ? buildInvoiceLinkStatusCell(
                                                          context,
                                                          message: message,
                                                          row: entry.value,
                                                          value:
                                                              tableCellValue(
                                                            entry.value,
                                                            column,
                                                          ),
                                                          cs: cs,
                                                          t: t,
                                                        )
                                                      : column['key']
                                                                  ?.toString() ==
                                                              'transactionLinkedStateLabel'
                                                          ? buildTransactionLinkedStateCell(
                                                              entry.value,
                                                              cs: cs,
                                                              t: t,
                                                              isEs: isEs,
                                                            )
                                                          : Align(
                                                              alignment: column[
                                                                              'align']
                                                                          ?.toString() ==
                                                                      'right'
                                                                  ? Alignment
                                                                      .centerRight
                                                                  : Alignment
                                                                      .centerLeft,
                                                              child:
                                                                  ConstrainedBox(
                                                                constraints:
                                                                    BoxConstraints(
                                                                  maxWidth: (column['key']?.toString() ==
                                                                              'description' ||
                                                                          column['key']?.toString() ==
                                                                              'concept')
                                                                      ? 360
                                                                      : 180,
                                                                ),
                                                                child: isInvoiceStatusColumn(
                                                                  column,
                                                                )
                                                                    ? (rowHasExistingInvoiceLink(
                                                                        entry
                                                                            .value,
                                                                      )
                                                                        ? buildLinkedInvoiceStatusCell(
                                                                            value:
                                                                                tableCellValue(
                                                                              entry.value,
                                                                              column,
                                                                            ),
                                                                            cs: cs,
                                                                            t: t,
                                                                            isDark:
                                                                                isDark,
                                                                          )
                                                                        : rowIsUnlinkedInvoice(
                                                                            entry.value,
                                                                          )
                                                                            ? buildUnlinkedInvoiceStatusCell(
                                                                                value: tableCellValue(
                                                                                  entry.value,
                                                                                  column,
                                                                                ),
                                                                                cs: cs,
                                                                                t: t,
                                                                                isDark: isDark,
                                                                              )
                                                                            : Text(
                                                                                tableCellValue(
                                                                                  entry.value,
                                                                                  column,
                                                                                ),
                                                                                maxLines: 1,
                                                                                overflow: TextOverflow.ellipsis,
                                                                                textAlign: column['align']?.toString() == 'right' ? TextAlign.right : TextAlign.left,
                                                                                style: cellStyle,
                                                                              ))
                                                                    : Text(
                                                                        tableCellValue(
                                                                          entry
                                                                              .value,
                                                                          column,
                                                                        ),
                                                                        maxLines:
                                                                            1,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                        textAlign: column['align']?.toString() ==
                                                                                'right'
                                                                            ? TextAlign.right
                                                                            : TextAlign.left,
                                                                        style:
                                                                            cellStyle,
                                                                      ),
                                                              ),
                                                            ),
                                        ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (tableLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            cs.surface.withValues(alpha: isDark ? 0.34 : 0.52),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.42),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEs ? 'Cargando tabla...' : 'Loading table...',
                              style: t.bodySmall.copyWith(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (hasSummaryBar) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tableFilterActive
                        ? (isEs ? 'Total filtrado' : 'Filtered total')
                        : summaryLabel ??
                            (hasMore
                                ? (isEs ? 'Total mostrado' : 'Displayed total')
                                : (isEs ? 'Total periodo' : 'Period total')),
                    style: t.bodySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: buildSummaryTrailing(),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (tableError != null &&
            tableError.isNotEmpty &&
            !(linkedIncomeReview && dataRows.isEmpty)) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: isDark ? 0.28 : 0.52),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.error.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tableError,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(
                      color: cs.onErrorContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: tableLoading
                      ? null
                      : linkedIncomeReview
                          ? () => refreshLinkedIncomeReview(message)
                          : () => changeRemoteTablePage(message, remotePage),
                  icon: const Icon(Icons.refresh_rounded, size: 14),
                  label: Text(isEs ? 'Reintentar' : 'Retry'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (tableFilterActive || hasMore || usesRemoteTable)
          const SizedBox(height: 12),
        if (tableFilterActive || hasMore || usesRemoteTable)
          Row(
            children: [
              Expanded(
                child: Text(
                  usesRemoteTable
                      ? (isEs
                          ? 'Mostrando ${dataRows.length} de $remoteTotalRows movimientos.'
                          : 'Showing ${dataRows.length} of $remoteTotalRows movements.')
                      : tableFilterActive
                          ? (isEs
                              ? 'Mostrando ${dataRows.length} de ${allDataRows.length} filas cargadas.'
                              : 'Showing ${dataRows.length} of ${allDataRows.length} loaded rows.')
                          : isFiniteNum(totalAvailable) &&
                                  isFiniteNum(truncatedTo)
                              ? (isEs
                                  ? 'Mostrando ${truncatedTo.toInt()} de ${totalAvailable.toInt()} filas.'
                                  : 'Showing ${truncatedTo.toInt()} of ${totalAvailable.toInt()} rows.')
                              : (isEs
                                  ? 'Hay mas resultados disponibles.'
                                  : 'More results are available.'),
                  style: t.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (usesRemoteTable) buildPaginationControls(),
            ],
          ),
      ],
    );
  }

}
