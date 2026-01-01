import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../statements_formatters.dart';
import 'statements_analytics_controller.dart';
import 'statements_analytics_widgets.dart';

class StatementsAnalyticsView extends StatefulWidget {
  const StatementsAnalyticsView({super.key});

  @override
  State<StatementsAnalyticsView> createState() =>
      _StatementsAnalyticsViewState();
}

class _StatementsAnalyticsViewState extends State<StatementsAnalyticsView>
    with AutomaticKeepAliveClientMixin {
  final List<int> _topOptions = const [5, 10, 20, 50];
  bool _showAllExpense = false;
  bool _showAllIncome = false;

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
      final batchWidth = width < 980 ? 240.0 : 300.0;
      final fieldWidth = width < 980 ? 170.0 : 200.0;
      final topWidth = width < 980 ? 120.0 : 140.0;

      Widget wrapField({required double width, required Widget child}) {
        return SizedBox(width: width, child: child);
      }

      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          wrapField(
            width: batchWidth,
            child: DropdownButtonFormField<String>(
              value: c.selectedBatchId,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsAnalyticsBatch,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
            width: fieldWidth,
            child: DropdownButtonFormField<int?>(
              value: c.selectedYear,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsFilterYear,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
            width: fieldWidth,
            child: DropdownButtonFormField<int?>(
              value: c.selectedMonth,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsAnalyticsMonth,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
            width: fieldWidth,
            child: DropdownButtonFormField<StatementsAnalyticsPeriodMode>(
              value: c.periodMode,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsAnalyticsMode,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
            width: fieldWidth,
            child: DropdownButtonFormField<StatementsAnalyticsCompareMode>(
              value: c.compareMode,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsAnalyticsCompareMode,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
              width: 120,
              child: DropdownButtonFormField<int>(
                value: c.settlementStartDay,
                isExpanded: true,
                style: t.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.statementsAnalyticsSettlementStart,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
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
              width: 120,
              child: DropdownButtonFormField<int>(
                value: c.settlementEndDay,
                isExpanded: true,
                style: t.bodyMedium,
                decoration: InputDecoration(
                  labelText: l.statementsAnalyticsSettlementEnd,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
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
              value: c.top,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                labelText: l.statementsAnalyticsTop,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
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
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.statementsAnalyticsTrends, style: t.titleLarge),
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
                        color: cs.surfaceVariant.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(12),
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

    Widget buildTopMerchants() {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l.statementsAnalyticsTopMerchants,
                        style: t.titleLarge),
                    const Spacer(),
                    SizedBox(
                      width: 140,
                      child: Text(
                        l.statementsAnalyticsTopHelp(c.top),
                        style: t.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
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
            color: cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
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
            color: cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
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
                final spacing = 12.0;
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

      return Card(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight = constraints.maxWidth < 980 ? 190.0 : 150.0;
        final headerMax = constraints.maxWidth < 980 ? 220.0 : 170.0;
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined),
                    const SizedBox(width: 8),
                    Text(l.statementsAnalyticsTitle, style: t.displayMedium),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                minHeight: headerHeight,
                maxHeight: headerMax,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    border: Border(
                      bottom:
                          BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildSelectors(constraints),
                      const SizedBox(height: 8),
                      Text(filterSummary(), style: t.bodySmall),
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
                  children: [
                    if (c.loadingSummary)
                      const AnalyticsSkeleton()
                    else if (c.summaryError != null)
                      Text(c.summaryError!,
                          style: t.bodySmall.copyWith(color: cs.error))
                    else ...[
                      buildTrend(),
                      const SizedBox(height: 12),
                      buildComparison(),
                      const SizedBox(height: 12),
                      buildTopMerchants(),
                      if (c.selectedMonth != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l.statementsAnalyticsMonthHint(c.selectedMonth!),
                            style: t.bodySmall
                                .copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ],
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
            color: cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}
