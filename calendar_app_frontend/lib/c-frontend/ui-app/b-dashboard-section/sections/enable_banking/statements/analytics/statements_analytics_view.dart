import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../enable_banking_left_nav.dart';
import '../../widgets/folder_section_card.dart';
import '../statements_formatters.dart';
import 'statements_analytics_copy.dart';
import 'statements_analytics_controller.dart';
import 'statements_analytics_widgets.dart';

class StatementsAnalyticsView extends StatefulWidget {
  const StatementsAnalyticsView({
    super.key,
    this.section = EnableBankingMenu.analyticsOverview,
  });

  final EnableBankingMenu section;

  @override
  State<StatementsAnalyticsView> createState() =>
      _StatementsAnalyticsViewState();
}

class _StatementsAnalyticsViewState extends State<StatementsAnalyticsView>
    with AutomaticKeepAliveClientMixin {
  final List<int> _topOptions = const [5, 10, 20, 50];
  bool _showAllExpense = false;
  bool _showAllIncome = false;
  bool _filtersExpanded = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StatementsAnalyticsController>().loadBatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.watch<StatementsAnalyticsController>();
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;

    final yearOptions = c.years
        .map((y) => int.tryParse(y['year']?.toString() ?? ''))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    final fallbackYears = List<int>.generate(6, (i) => DateTime.now().year - i);
    final availableYears = yearOptions.isEmpty ? fallbackYears : yearOptions;

    final monthOptions = List<int>.generate(12, (i) => i + 1);
    final dayOptions = List<int>.generate(31, (i) => i + 1);
    final compareOptions = <StatementsAnalyticsCompareMode, String>{
      StatementsAnalyticsCompareMode.both: l.statementsAnalyticsCompareBoth,
      StatementsAnalyticsCompareMode.calendarOnly:
          l.statementsAnalyticsCompareCalendar,
      StatementsAnalyticsCompareMode.settlementOnly:
          l.statementsAnalyticsCompareSettlement,
      StatementsAnalyticsCompareMode.delta: l.statementsAnalyticsCompareDelta,
    };

    String filterSummary() {
      final parts = <String>[];
      final modeLabel =
          c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow
              ? l.statementsAnalyticsModeSettlement
              : l.statementsAnalyticsModeCalendar;
      parts.add(l.statementsAnalyticsModeLabel(modeLabel));
      parts.add(
          '${l.statementsAnalyticsBatch}: ${c.selectedBatchId == 'all' ? l.statementsAnalyticsAllBatches : c.selectedBatchId}');
      if (c.selectedYear != null) {
        parts.add('${l.statementsFilterYear}: ${c.selectedYear}');
      }
      if (c.selectedMonth != null) {
        parts.add('${l.statementsAnalyticsMonth}: ${c.selectedMonth}');
      }
      parts.add('${l.statementsAnalyticsTop}: ${c.top}');
      if (c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow) {
        final range = c.settlementRange();
        if (range == null) {
          parts.add(l.statementsAnalyticsPeriodPending);
        } else {
          final from = StatementsFormatters.formatDate(context, range.start);
          final to = StatementsFormatters.formatDate(context, range.end);
          parts.add(l.statementsAnalyticsPeriodLabel(from, to));
        }
      }
      return parts.join(' • ');
    }

    Widget buildSelectors(BoxConstraints constraints) {
      final width = constraints.maxWidth;
      final batchWidth = width < 980 ? 200.0 : 220.0;
      const yearWidth = 110.0;
      final monthWidth = width < 980 ? 150.0 : 160.0;
      final modeWidth = width < 980 ? 150.0 : 165.0;
      final compareWidth = width < 980 ? 160.0 : 175.0;
      const topWidth = 92.0;

      Widget wrapField({required double width, required Widget child}) {
        return SizedBox(width: width, child: child);
      }

      InputDecoration compactDecoration(String label) {
        return InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: cs.primary, width: 1.5),
          ),
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          wrapField(
            width: batchWidth,
            child: DropdownButtonFormField<String>(
              initialValue: c.selectedBatchId,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsAnalyticsBatch),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    l.statementsAnalyticsAllBatches,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...c.batches.map((b) {
                  final id =
                      (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ?? '';
                  final name =
                      (b['originalName'] ?? b['filename'])?.toString() ?? id;
                  return DropdownMenuItem(
                    value: id,
                    child: Text(name, overflow: TextOverflow.ellipsis),
                  );
                })
              ],
              onChanged: (v) => c.selectBatch(v),
            ),
          ),
          wrapField(
            width: yearWidth,
            child: DropdownButtonFormField<int?>(
              initialValue: c.selectedYear,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsFilterYear),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    l.statementsAnalyticsAllYears,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...availableYears.map(
                  (y) => DropdownMenuItem(value: y, child: Text(y.toString())),
                ),
              ],
              onChanged: (v) => c.setYear(v),
            ),
          ),
          wrapField(
            width: monthWidth,
            child: DropdownButtonFormField<int?>(
              initialValue: c.selectedMonth,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsAnalyticsMonth),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(
                    l.statementsAnalyticsAllMonths,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...monthOptions.map(
                  (m) => DropdownMenuItem(value: m, child: Text(m.toString())),
                ),
              ],
              onChanged: c.selectedYear == null ? null : (v) => c.setMonth(v),
            ),
          ),
          wrapField(
            width: modeWidth,
            child: DropdownButtonFormField<StatementsAnalyticsPeriodMode>(
              initialValue: c.periodMode,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsAnalyticsMode),
              items: [
                DropdownMenuItem(
                  value: StatementsAnalyticsPeriodMode.calendarMonth,
                  child: Text(l.statementsAnalyticsModeCalendar),
                ),
                DropdownMenuItem(
                  value: StatementsAnalyticsPeriodMode.settlementWindow,
                  child: Text(l.statementsAnalyticsModeSettlement),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                c.setPeriodMode(v);
              },
            ),
          ),
          wrapField(
            width: compareWidth,
            child: DropdownButtonFormField<StatementsAnalyticsCompareMode>(
              initialValue: c.compareMode,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsAnalyticsCompareMode),
              items: compareOptions.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                c.setCompareMode(v);
              },
            ),
          ),
          if (c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow)
            wrapField(
              width: 96,
              child: DropdownButtonFormField<int>(
                initialValue: c.settlementStartDay,
                isExpanded: true,
                style: t.bodyMedium,
                decoration:
                    compactDecoration(l.statementsAnalyticsSettlementStart),
                items: dayOptions
                    .map(
                      (d) =>
                          DropdownMenuItem(value: d, child: Text(d.toString())),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  c.setSettlementStartDay(v);
                },
              ),
            ),
          if (c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow)
            wrapField(
              width: 96,
              child: DropdownButtonFormField<int>(
                initialValue: c.settlementEndDay,
                isExpanded: true,
                style: t.bodyMedium,
                decoration:
                    compactDecoration(l.statementsAnalyticsSettlementEnd),
                items: dayOptions
                    .map(
                      (d) =>
                          DropdownMenuItem(value: d, child: Text(d.toString())),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  c.setSettlementEndDay(v);
                },
              ),
            ),
          wrapField(
            width: topWidth,
            child: DropdownButtonFormField<int>(
              initialValue: c.top,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: compactDecoration(l.statementsAnalyticsTop),
              items: _topOptions
                  .map((v) =>
                      DropdownMenuItem(value: v, child: Text(v.toString())))
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                c.setTop(v);
              },
            ),
          ),
        ],
      );
    }

    Widget buildFilterChips() {
      Widget chip(String label, {VoidCallback? onDelete}) {
        final active = onDelete != null;
        return MouseRegion(
          cursor:
              active ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.only(
                left: 10, right: active ? 6 : 10, top: 5, bottom: 5),
            decoration: BoxDecoration(
              color: active
                  ? cs.primaryContainer.withValues(alpha: 0.85)
                  : cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? cs.primary.withValues(alpha: 0.25)
                    : cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: t.bodySmall.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
                if (active) ...[
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 10,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }

      final chips = <Widget>[];
      final batchLabel = c.selectedBatchId == null ||
              c.selectedBatchId == 'all'
          ? l.statementsAnalyticsAllBatches
          : c.selectedBatchId!;
      final modeLabel =
          c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow
              ? l.statementsAnalyticsModeSettlement
              : l.statementsAnalyticsModeCalendar;
      final compareLabel = compareOptions[c.compareMode]!;

      chips.add(chip(
        '${l.statementsAnalyticsBatch}: $batchLabel',
        onDelete: c.selectedBatchId == null || c.selectedBatchId == 'all'
            ? null
            : () => c.selectBatch('all'),
      ));
      chips.add(chip(
        '${l.statementsAnalyticsMode}: $modeLabel',
        onDelete: c.periodMode == StatementsAnalyticsPeriodMode.calendarMonth
            ? null
            : () =>
                c.setPeriodMode(StatementsAnalyticsPeriodMode.calendarMonth),
      ));
      chips.add(chip(
        '${l.statementsAnalyticsCompareMode}: $compareLabel',
        onDelete: c.compareMode == StatementsAnalyticsCompareMode.both
            ? null
            : () => c.setCompareMode(StatementsAnalyticsCompareMode.both),
      ));
      chips.add(chip(
        '${l.statementsAnalyticsTop}: ${c.top}',
        onDelete: c.top == _topOptions.first
            ? null
            : () => c.setTop(_topOptions.first),
      ));
      if (c.selectedYear != null) {
        chips.add(chip(
          '${l.statementsFilterYear}: ${c.selectedYear}',
          onDelete: () => c.setYear(null),
        ));
      }
      if (c.selectedMonth != null) {
        chips.add(chip(
          '${l.statementsAnalyticsMonth}: ${c.selectedMonth}',
          onDelete: () => c.setMonth(null),
        ));
      }
      if (c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow) {
        final range = c.settlementRange();
        if (range != null) {
          final from = StatementsFormatters.formatDate(context, range.start);
          final to = StatementsFormatters.formatDate(context, range.end);
          chips.add(chip(l.statementsAnalyticsPeriodLabel(from, to)));
        }
      }
      return Wrap(spacing: 8, runSpacing: 6, children: chips);
    }

    Widget buildTrend() {
      final useSettlement =
          c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow &&
              c.selectedYear != null &&
              c.compareRows.isNotEmpty;
      final baseRows = useSettlement
          ? c.compareRows
              .map(
                (row) => {
                  'year': row.year,
                  'month': row.month,
                  'income': row.settlementTotals.income,
                  'expense': row.settlementTotals.expense,
                  'net': row.settlementTotals.net,
                  'count': row.settlementTotals.count,
                },
              )
              .toList()
          : (c.selectedYear == null ? c.years : c.months);

      List<Map<String, dynamic>> buildAverageRows() {
        return baseRows.map((row) {
          final count = (row['count'] as num?)?.toDouble() ?? 0;
          final divisor = count == 0 ? 1.0 : count;
          return {
            ...row,
            'income': ((row['income'] as num?)?.toDouble() ?? 0) / divisor,
            'expense': ((row['expense'] as num?)?.toDouble() ?? 0) / divisor,
            'net': ((row['net'] as num?)?.toDouble() ?? 0) / divisor,
          };
        }).toList();
      }

      String labelBuilder(Map<String, dynamic> row) {
        final year = row['year']?.toString() ?? '-';
        final month = row['month']?.toString();
        if (c.selectedYear == null || month == null || month.isEmpty) {
          return year;
        }
        return month.padLeft(2, '0');
      }

      final averageRows = buildAverageRows();
      return FolderSectionCard(
        label: l.statementsAnalyticsTrends,
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(l.statementsAnalyticsTrendsHelp, style: t.bodySmall),
              if (c.selectedYear == null && c.years.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l.statementsAnalyticsYearAveragesTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: c.years.map((row) {
                    final year = row['year']?.toString() ?? '-';
                    final income = (row['income'] as num?) ?? 0;
                    final expense = (row['expense'] as num?) ?? 0;
                    final avgIncome = income / 12;
                    final avgExpense = expense / 12;
                    return Container(
                      width: 240,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            cs.surfaceContainerHighest.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(year,
                              style: t.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text(
                            '${l.statementsAnalyticsAverageIncome}: ${StatementsFormatters.formatCurrency(context, avgIncome)}',
                            style: t.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${l.statementsAnalyticsAverageExpense}: ${StatementsFormatters.formatCurrency(context, avgExpense)}',
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TabBar(
                      labelStyle: t.bodyMedium,
                      tabs: [
                        Tab(text: l.statementsAnalyticsTotalsTab),
                        Tab(text: l.statementsAnalyticsAverageTab),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 360,
                      child: TabBarView(
                        children: [
                          AnalyticsTrendChart(
                            rows: baseRows,
                            labelBuilder: labelBuilder,
                          ),
                          AnalyticsTrendChart(
                            rows: averageRows,
                            labelBuilder: labelBuilder,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildOverview() {
      final rows = c.selectedYear == null ? c.years : c.months;
      final income =
          rows.fold<num>(0, (sum, row) => sum + ((row['income'] as num?) ?? 0));
      final expense = rows.fold<num>(
          0, (sum, row) => sum + ((row['expense'] as num?) ?? 0));
      final net =
          rows.fold<num>(0, (sum, row) => sum + ((row['net'] as num?) ?? 0));
      final count =
          rows.fold<num>(0, (sum, row) => sum + ((row['count'] as num?) ?? 0));
      final topExpenseMerchant = c.topExpense.isEmpty
          ? null
          : c.topExpense.first['merchant']?.toString();
      final topIncomeMerchant = c.topIncome.isEmpty
          ? null
          : c.topIncome.first['merchant']?.toString();
      final isSettlement =
          c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow;

      Widget summaryCard({
        required String title,
        required String value,
        String? subtitle,
        IconData? icon,
      }) {
        return Container(
          width: 240,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(height: 10),
              ],
              Text(
                title,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle, style: t.caption),
              ],
            ],
          ),
        );
      }

      return FolderSectionCard(
        label: l.statementsSummaryTitle,
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSettlement
                    ? l.statementsAnalyticsModeLabel(
                        l.statementsAnalyticsModeSettlement)
                    : l.statementsAnalyticsModeLabel(
                        l.statementsAnalyticsModeCalendar),
                style: t.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  summaryCard(
                    title: l.statementsSummaryIncome,
                    value: StatementsFormatters.formatCurrency(context, income),
                    subtitle: l.statementsEntryCount(count.toString()),
                    icon: Icons.south_west_rounded,
                  ),
                  summaryCard(
                    title: l.statementsSummaryExpense,
                    value:
                        StatementsFormatters.formatCurrency(context, expense),
                    subtitle: c.selectedYear == null
                        ? l.statementsAnalyticsAllYears
                        : '${l.statementsFilterYear}: ${c.selectedYear}',
                    icon: Icons.north_east_rounded,
                  ),
                  summaryCard(
                    title: l.statementsSummaryNet,
                    value: StatementsFormatters.formatCurrency(context, net),
                    subtitle: c.selectedMonth == null
                        ? l.statementsAnalyticsAllMonths
                        : '${l.statementsAnalyticsMonth}: ${c.selectedMonth}',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  summaryCard(
                    title: l.statementsAnalyticsTopMerchants,
                    value: topExpenseMerchant ?? '-',
                    subtitle: topIncomeMerchant == null
                        ? null
                        : '${l.statementsSummaryIncome}: $topIncomeMerchant',
                    icon: Icons.storefront_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget buildTopMerchants() {
      return FolderSectionCard(
        label: l.statementsAnalyticsTopMerchants,
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(l.statementsAnalyticsTopHelpSubtitle, style: t.bodySmall),
                const SizedBox(height: 8),
                TabBar(
                  labelStyle: t.bodyMedium,
                  tabs: [
                    Tab(text: l.statementsSummaryExpense),
                    Tab(text: l.statementsSummaryIncome),
                  ],
                ),
                const SizedBox(
                  height: 16,
                ),
                SizedBox(
                  height: 380,
                  child: TabBarView(
                    children: [
                      TopMerchantsChart(
                        rows: c.topExpense,
                        title: l.statementsSummaryExpense,
                        expanded: _showAllExpense,
                        onToggle: () =>
                            setState(() => _showAllExpense = !_showAllExpense),
                      ),
                      TopMerchantsChart(
                        rows: c.topIncome,
                        title: l.statementsSummaryIncome,
                        expanded: _showAllIncome,
                        onToggle: () =>
                            setState(() => _showAllIncome = !_showAllIncome),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget buildComparison() {
      if (c.selectedYear == null) {
        return Text(
          l.statementsAnalyticsComparePickYear,
          style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
        );
      }
      if (c.loadingCompare) {
        return const AnalyticsSkeleton();
      }
      if (c.compareError != null) {
        return Text(c.compareError!,
            style: t.bodySmall.copyWith(color: cs.error));
      }
      if (c.compareRows.isEmpty) {
        return Text(l.statementsAnalyticsNoData, style: t.bodySmall);
      }

      Widget buildYearAverageCard() {
        final useSettlement =
            c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow;
        final totals = c.compareRows.map((row) {
          return useSettlement ? row.settlementTotals : row.calendarTotals;
        }).toList();
        final count = totals.isEmpty ? 1 : totals.length;
        final avgIncome =
            totals.fold<num>(0, (sum, t) => sum + t.income) / count;
        final avgExpense =
            totals.fold<num>(0, (sum, t) => sum + t.expense) / count;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.statementsAnalyticsYearAverageTitle,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${l.statementsAnalyticsAverageIncome}: ${StatementsFormatters.formatCurrency(context, avgIncome)}',
                style: t.bodySmall,
              ),
              const SizedBox(height: 2),
              Text(
                '${l.statementsAnalyticsAverageExpense}: ${StatementsFormatters.formatCurrency(context, avgExpense)}',
                style: t.bodySmall,
              ),
            ],
          ),
        );
      }

      Widget buildTotals(StatementsAnalyticsTotals totals) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.statementsSummaryIncome}: ${StatementsFormatters.formatCurrency(context, totals.income)}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${l.statementsSummaryExpense}: ${StatementsFormatters.formatCurrency(context, totals.expense)}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              '${l.statementsSummaryNet}: ${StatementsFormatters.formatCurrency(context, totals.net)}',
              style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              l.statementsEntryCount(totals.count.toString()),
              style: t.caption,
            ),
          ],
        );
      }

      Widget buildPeriodCard({
        required String title,
        required DateTime start,
        required DateTime end,
        required StatementsAnalyticsTotals totals,
      }) {
        final from = StatementsFormatters.formatDate(context, start);
        final to = StatementsFormatters.formatDate(context, end);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l.statementsAnalyticsPeriodLabel(from, to),
                  style: t.caption),
              const SizedBox(height: 8),
              buildTotals(totals),
            ],
          ),
        );
      }

      Widget buildRow(StatementsAnalyticsCompareRow row) {
        final monthLabel = row.month.toString().padLeft(2, '0');
        final showCalendar =
            c.compareMode != StatementsAnalyticsCompareMode.settlementOnly;
        final showSettlement =
            c.compareMode != StatementsAnalyticsCompareMode.calendarOnly;
        final showDelta = c.compareMode == StatementsAnalyticsCompareMode.delta;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l.statementsAnalyticsMonth} $monthLabel',
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    if (showCalendar && !showDelta)
                      SizedBox(
                        width: constraints.maxWidth < 720
                            ? constraints.maxWidth
                            : (constraints.maxWidth - spacing) / 2,
                        child: buildPeriodCard(
                          title: l.statementsAnalyticsCompareCalendar,
                          start: row.calendarStart,
                          end: row.calendarEnd,
                          totals: row.calendarTotals,
                        ),
                      ),
                    if (showSettlement && !showDelta)
                      SizedBox(
                        width: constraints.maxWidth < 720
                            ? constraints.maxWidth
                            : (constraints.maxWidth - spacing) / 2,
                        child: buildPeriodCard(
                          title: l.statementsAnalyticsCompareSettlement,
                          start: row.settlementStart,
                          end: row.settlementEnd,
                          totals: row.settlementTotals,
                        ),
                      ),
                    if (showDelta)
                      SizedBox(
                        width: constraints.maxWidth < 720
                            ? constraints.maxWidth
                            : (constraints.maxWidth - spacing) / 2,
                        child: buildPeriodCard(
                          title: l.statementsAnalyticsCompareDelta,
                          start: row.calendarStart,
                          end: row.settlementEnd,
                          totals: row.delta,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      }

      return FolderSectionCard(
        label: l.statementsAnalyticsCompareTitle,
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.statementsAnalyticsCompareTitle, style: t.titleLarge),
              const SizedBox(height: 4),
              Text(l.statementsAnalyticsCompareHelp, style: t.bodySmall),
              const SizedBox(height: 12),
              buildYearAverageCard(),
              const SizedBox(height: 12),
              ...c.compareRows.map((row) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: buildRow(row),
                  )),
            ],
          ),
        ),
      );
    }

    Widget buildSplit() {
      final totals = c.visibleTotals;
      if (totals.count == 0 && totals.income == 0 && totals.expense == 0) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.splitTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(message: l.statementsAnalyticsNoData),
          ),
        );
      }
      final incomeLabel =
          StatementsFormatters.formatCurrency(context, totals.income);
      final expenseLabel =
          StatementsFormatters.formatCurrency(context, totals.expense);
      final netLabel = StatementsFormatters.formatCurrency(context, totals.net);
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.splitTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth =
                  constraints.maxWidth < 860 ? constraints.maxWidth : 340.0;
              final metricWidth = constraints.maxWidth < 860
                  ? constraints.maxWidth
                  : constraints.maxWidth - chartWidth - 16;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: chartWidth,
                    child: AnalyticsDonutChart(
                      slices: [
                        AnalyticsDonutSlice(
                          label: l.statementsSummaryIncome,
                          value: totals.income,
                          color: const Color(0xFF2E7D32),
                          legendValue: incomeLabel,
                          tooltipValue: incomeLabel,
                        ),
                        AnalyticsDonutSlice(
                          label: l.statementsSummaryExpense,
                          value: totals.expense,
                          color: const Color(0xFFC62828),
                          legendValue: expenseLabel,
                          tooltipValue: expenseLabel,
                        ),
                      ],
                      centerLabel: l.statementsSummaryNet,
                      centerValue: netLabel,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StatementsAnalyticsCopy.splitSubtitle(context),
                          style: t.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            AnalyticsMetricCard(
                              title: l.statementsSummaryIncome,
                              value: incomeLabel,
                              subtitle: l.statementsEntryCount(
                                totals.count.toString(),
                              ),
                              icon: Icons.arrow_downward_rounded,
                            ),
                            AnalyticsMetricCard(
                              title: l.statementsSummaryExpense,
                              value: expenseLabel,
                              subtitle: c.selectedMonth == null
                                  ? l.statementsAnalyticsAllMonths
                                  : '${l.statementsAnalyticsMonth}: ${c.selectedMonth}',
                              icon: Icons.arrow_upward_rounded,
                            ),
                            AnalyticsMetricCard(
                              title: l.statementsSummaryNet,
                              value: netLabel,
                              subtitle: c.selectedYear == null
                                  ? l.statementsAnalyticsAllYears
                                  : '${l.statementsFilterYear}: ${c.selectedYear}',
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    Widget buildVolume() {
      final points = c.volumePoints;
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.volumeTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      StatementsAnalyticsCopy.volumeSubtitle(context),
                      style: t.bodySmall,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      c.volumeUsesDaily
                          ? StatementsAnalyticsCopy.volumeDailyLabel(context)
                          : StatementsAnalyticsCopy.volumePeriodLabel(context),
                      style: t.caption.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (c.loadingEntries && c.selectedMonth != null)
                const LinearProgressIndicator(minHeight: 2),
              if (c.loadingEntries && c.selectedMonth != null)
                const SizedBox(height: 12),
              AnalyticsVolumeChart(points: points),
            ],
          ),
        ),
      );
    }

    Widget buildTicket() {
      if (c.loadingEntries) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.ticketTitle(context),
          leftTabOffset: 0,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AnalyticsSkeleton(),
          ),
        );
      }
      if (c.entriesError != null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.ticketTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: c.entriesError!,
              icon: Icons.error_outline,
              color: cs.error,
            ),
          ),
        );
      }
      final stats = c.ticketStats;
      if (stats == null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.ticketTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: StatementsAnalyticsCopy.noEntriesLabel(context),
            ),
          ),
        );
      }
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.ticketTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StatementsAnalyticsCopy.ticketSubtitle(context),
                style: t.bodySmall,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.averageIncomeLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.averageIncome,
                    ),
                    subtitle: '${stats.incomeCount} ingresos',
                    icon: Icons.south_west_rounded,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.averageExpenseLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.averageExpense,
                    ),
                    subtitle: '${stats.expenseCount} gastos',
                    icon: Icons.north_east_rounded,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.largestIncomeLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.largestIncome,
                    ),
                    icon: Icons.trending_up_rounded,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.largestExpenseLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.largestExpense,
                    ),
                    icon: Icons.trending_down_rounded,
                  ),
                  AnalyticsMetricCard(
                    title:
                        StatementsAnalyticsCopy.totalTransactionsLabel(context),
                    value: StatementsFormatters.formatCount(
                      context,
                      stats.transactionCount,
                    ),
                    subtitle: l.statementsEntryCount(
                      stats.transactionCount.toString(),
                    ),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget buildLinked() {
      if (c.loadingEntries) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.linkedTitle(context),
          leftTabOffset: 0,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AnalyticsSkeleton(),
          ),
        );
      }
      if (c.entriesError != null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.linkedTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: c.entriesError!,
              icon: Icons.error_outline,
              color: cs.error,
            ),
          ),
        );
      }
      final stats = c.linkStats;
      if (stats == null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.linkedTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: StatementsAnalyticsCopy.noEntriesLabel(context),
            ),
          ),
        );
      }
      final linkedLabel = StatementsFormatters.formatCount(
        context,
        stats.linkedCount,
      );
      final unlinkedLabel = StatementsFormatters.formatCount(
        context,
        stats.unlinkedCount,
      );
      final linkedPct =
          '${StatementsFormatters.formatAmount(context, stats.linkedRatio * 100)}%';
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.linkedTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth =
                  constraints.maxWidth < 860 ? constraints.maxWidth : 340.0;
              final metricWidth = constraints.maxWidth < 860
                  ? constraints.maxWidth
                  : constraints.maxWidth - chartWidth - 16;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: chartWidth,
                    child: AnalyticsDonutChart(
                      slices: [
                        AnalyticsDonutSlice(
                          label: StatementsAnalyticsCopy.linkedLabel(context),
                          value: stats.linkedCount,
                          color: const Color(0xFF1565C0),
                          legendValue: linkedLabel,
                          tooltipValue: linkedLabel,
                        ),
                        AnalyticsDonutSlice(
                          label:
                              StatementsAnalyticsCopy.unlinkedLabel(context),
                          value: stats.unlinkedCount,
                          color: const Color(0xFFEF6C00),
                          legendValue: unlinkedLabel,
                          tooltipValue: unlinkedLabel,
                        ),
                      ],
                      centerLabel: StatementsAnalyticsCopy.linkedRateLabel(
                        context,
                      ),
                      centerValue: linkedPct,
                    ),
                  ),
                  SizedBox(
                    width: metricWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          StatementsAnalyticsCopy.linkedSubtitle(context),
                          style: t.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            AnalyticsMetricCard(
                              title:
                                  StatementsAnalyticsCopy.linkedLabel(context),
                              value: linkedLabel,
                              icon: Icons.link_outlined,
                            ),
                            AnalyticsMetricCard(
                              title: StatementsAnalyticsCopy.unlinkedLabel(
                                context,
                              ),
                              value: unlinkedLabel,
                              icon: Icons.link_off_outlined,
                            ),
                            AnalyticsMetricCard(
                              title:
                                  StatementsAnalyticsCopy.linkedRateLabel(
                                context,
                              ),
                              value: linkedPct,
                              subtitle:
                                  '${stats.total} movimientos analizados',
                              icon: Icons.analytics_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    Widget buildActivity() {
      if (c.loadingEntries) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.activityTitle(context),
          leftTabOffset: 0,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AnalyticsSkeleton(),
          ),
        );
      }
      if (c.entriesError != null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.activityTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: c.entriesError!,
              icon: Icons.error_outline,
              color: cs.error,
            ),
          ),
        );
      }
      final days = c.heatmapDays;
      if (days.isEmpty) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.activityTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: StatementsAnalyticsCopy.noEntriesLabel(context),
            ),
          ),
        );
      }
      final activeDays = days.where((day) => day.count > 0).length;
      var peakDay = days.first;
      for (final day in days.skip(1)) {
        if (day.count > peakDay.count) peakDay = day;
      }
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.activityTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StatementsAnalyticsCopy.activitySubtitle(context),
                style: t.bodySmall,
              ),
              const SizedBox(height: 12),
              AnalyticsHeatmap(days: days),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AnalyticsMetricCard(
                    title:
                        StatementsAnalyticsCopy.activityActiveDaysLabel(context),
                    value: StatementsFormatters.formatCount(
                      context,
                      activeDays,
                    ),
                    icon: Icons.calendar_today_outlined,
                  ),
                  AnalyticsMetricCard(
                    title:
                        StatementsAnalyticsCopy.activityPeakDayLabel(context),
                    value: StatementsFormatters.formatDate(
                      context,
                      peakDay.date,
                    ),
                    subtitle: '${peakDay.count} movimientos',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget buildStatus() {
      if (c.loadingStatus) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.statusTitle(context),
          leftTabOffset: 0,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: AnalyticsSkeleton(),
          ),
        );
      }
      if (c.statusError != null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.statusTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: c.statusError!,
              icon: Icons.error_outline,
              color: cs.error,
            ),
          ),
        );
      }
      final status = c.statusSnapshot;
      if (status == null) {
        return FolderSectionCard(
          label: StatementsAnalyticsCopy.statusTitle(context),
          leftTabOffset: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnalyticsStateMessage(
              message: StatementsAnalyticsCopy.noStatusLabel(context),
            ),
          ),
        );
      }
      final badgeColor = status.mixed
          ? cs.tertiary
          : (status.stale ? cs.error : const Color(0xFF2E7D32));
      final badgeLabel = status.mixed
          ? StatementsAnalyticsCopy.mixedLabel(context)
          : (status.stale
              ? StatementsAnalyticsCopy.staleLabel(context)
              : StatementsAnalyticsCopy.freshLabel(context));
      return FolderSectionCard(
        label: StatementsAnalyticsCopy.statusTitle(context),
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      StatementsAnalyticsCopy.statusSubtitle(context),
                      style: t.bodySmall,
                    ),
                  ),
                  AnalyticsStatusBadge(
                    label: badgeLabel,
                    color: badgeColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AnalyticsMetricCard(
                    title:
                        StatementsAnalyticsCopy.lastTransactionLabel(context),
                    value: status.lastDate == null
                        ? '-'
                        : StatementsFormatters.formatDate(
                            context,
                            status.lastDate,
                          ),
                    icon: Icons.event_outlined,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.daysSinceLabel(context),
                    value: status.daysSince == null
                        ? '-'
                        : status.daysSince.toString(),
                    icon: Icons.timelapse_rounded,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.thresholdLabel(context),
                    value: status.thresholdDays == null
                        ? '-'
                        : status.thresholdDays.toString(),
                    icon: Icons.flag_outlined,
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.batchesMonitoredLabel(
                      context,
                    ),
                    value: status.totalBatches.toString(),
                    subtitle:
                        '${status.freshBatches} frescos · ${status.staleBatches} atrasados',
                    icon: Icons.layers_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (c.loadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }

    if (c.batchesError != null) {
      return Center(
          child: Text(c.batchesError!,
              style: t.bodySmall.copyWith(color: cs.error)));
    }

    if (c.batches.isEmpty) {
      return Center(
          child: Text(l.statementsAnalyticsNoBatches, style: t.bodySmall));
    }

    if (c.selectedBatchId == null) {
      return Center(
          child: Text(l.statementsAnalyticsNoSelection, style: t.bodySmall));
    }

    final sectionChildren = <Widget>[];
    if (c.loadingSummary) {
      sectionChildren.add(const AnalyticsSkeleton());
    } else if (c.summaryError != null) {
      sectionChildren.add(
        Text(c.summaryError!, style: t.bodySmall.copyWith(color: cs.error)),
      );
    } else if (widget.section == EnableBankingMenu.analyticsOverview) {
      sectionChildren.add(buildOverview());
    } else if (widget.section == EnableBankingMenu.analyticsSplit) {
      sectionChildren.add(buildSplit());
    } else if (widget.section == EnableBankingMenu.analyticsVolume) {
      sectionChildren.add(buildVolume());
    } else if (widget.section == EnableBankingMenu.analyticsTicket) {
      sectionChildren.add(buildTicket());
    } else if (widget.section == EnableBankingMenu.analyticsLinked) {
      sectionChildren.add(buildLinked());
    } else if (widget.section == EnableBankingMenu.analyticsActivity) {
      sectionChildren.add(buildActivity());
    } else if (widget.section == EnableBankingMenu.analyticsStatus) {
      sectionChildren.add(buildStatus());
    } else if (widget.section == EnableBankingMenu.analyticsTrends) {
      sectionChildren.add(buildTrend());
      if (c.selectedMonth != null) {
        sectionChildren.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l.statementsAnalyticsMonthHint(c.selectedMonth!),
              style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        );
      }
    } else if (widget.section == EnableBankingMenu.analyticsTopMerchants) {
      sectionChildren.add(buildTopMerchants());
    } else if (widget.section == EnableBankingMenu.analyticsComparison) {
      sectionChildren.add(buildComparison());
    } else {
      sectionChildren.add(buildOverview());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;
        final headerHeight = _filtersExpanded
            ? (isNarrow ? 190.0 : 138.0)
            : (isNarrow ? 106.0 : 82.0);
        final headerMax = _filtersExpanded
            ? (isNarrow ? 220.0 : 162.0)
            : (isNarrow ? 124.0 : 96.0);
        return CustomScrollView(
          slivers: [
            // SliverToBoxAdapter(
            //   child: Padding(
            //     padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            //     child: Row(
            //       children: [
            //         const Icon(Icons.analytics_outlined),
            //         const SizedBox(width: 8),
            //         Text(l.statementsAnalyticsTitle, style: t.displayMedium),
            //       ],
            //     ),
            //   ),
            // ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                minHeight: headerHeight,
                maxHeight: headerMax,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.tune_rounded,
                              size: 14,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _filtersExpanded
                                ? l.statementsFiltersTitle
                                : l.statementsFiltersActive,
                            style: t.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: () => setState(
                                () => _filtersExpanded = !_filtersExpanded),
                            icon: Icon(
                              _filtersExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.tune_rounded,
                              size: 15,
                            ),
                            label: Text(_filtersExpanded
                                ? l.statementsAnalyticsCollapse
                                : l.statementsAnalyticsExpand),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_filtersExpanded) ...[
                        buildSelectors(constraints),
                        const SizedBox(height: 8),
                        Tooltip(
                          message: filterSummary(),
                          child: buildFilterChips(),
                        ),
                      ] else ...[
                        Tooltip(
                          message: filterSummary(),
                          child: buildFilterChips(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sectionChildren,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}

class AnalyticsSkeleton extends StatelessWidget {
  const AnalyticsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
