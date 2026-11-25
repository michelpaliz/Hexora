import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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
  int _merchantTab = 0; // 0 = Gastos (expense), 1 = Ingresos (income)

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

    Widget buildSelectors(BoxConstraints constraints) {
      final fieldWidth = constraints.maxWidth;

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
              const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        );
      }

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          wrapField(
            width: fieldWidth,
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
            width: fieldWidth,
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
            width: fieldWidth,
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
            width: fieldWidth,
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
            width: fieldWidth,
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
              width: fieldWidth,
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
              width: fieldWidth,
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
            width: fieldWidth,
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

    String reportTitle() => switch (widget.section) {
          EnableBankingMenu.analyticsSplit =>
            StatementsAnalyticsCopy.splitTitle(context),
          EnableBankingMenu.analyticsVolume =>
            StatementsAnalyticsCopy.volumeTitle(context),
          EnableBankingMenu.analyticsTicket =>
            StatementsAnalyticsCopy.ticketTitle(context),
          EnableBankingMenu.analyticsLinked =>
            StatementsAnalyticsCopy.linkedTitle(context),
          EnableBankingMenu.analyticsActivity =>
            StatementsAnalyticsCopy.activityTitle(context),
          EnableBankingMenu.analyticsStatus =>
            StatementsAnalyticsCopy.statusTitle(context),
          EnableBankingMenu.analyticsTrends => l.statementsAnalyticsTrends,
          EnableBankingMenu.analyticsTopMerchants =>
            StatementsAnalyticsCopy.topMerchantsMenu(context),
          EnableBankingMenu.analyticsComparison =>
            StatementsAnalyticsCopy.comparisonMenu(context),
          _ => StatementsAnalyticsCopy.billableOverviewLabel(context),
        };

    Widget filterPanel({VoidCallback? onClose, double contentWidth = 276}) {
      final maxHeight = MediaQuery.sizeOf(context).height * 0.68;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight.clamp(320, 560).toDouble(),
        ),
        child: Material(
          color: cs.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.statementsFiltersTitle,
                        style: t.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        tooltip: l.dialogClose,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 19),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 2),
                    child: buildSelectors(
                      BoxConstraints.tightFor(width: contentWidth),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      final isExpense = _merchantTab == 0;
      return FolderSectionCard(
        label: l.statementsAnalyticsTopMerchants,
        leftTabOffset: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(l.statementsAnalyticsTopHelpSubtitle, style: t.bodySmall),
              const SizedBox(height: 10),
              AnalyticsSegmented<int>(
                value: _merchantTab,
                onChanged: (v) => setState(() => _merchantTab = v),
                segments: [
                  AnalyticsSegment(
                    value: 0,
                    label: l.statementsSummaryExpense,
                  ),
                  AnalyticsSegment(
                    value: 1,
                    label: l.statementsSummaryIncome,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: TopMerchantsChart(
                  key: ValueKey('top-merchants-$_merchantTab'),
                  rows: isExpense ? c.topExpense : c.topIncome,
                  title: isExpense
                      ? l.statementsSummaryExpense
                      : l.statementsSummaryIncome,
                  isExpense: isExpense,
                  expanded: isExpense ? _showAllExpense : _showAllIncome,
                  onToggle: () => setState(() {
                    if (isExpense) {
                      _showAllExpense = !_showAllExpense;
                    } else {
                      _showAllIncome = !_showAllIncome;
                    }
                  }),
                ),
              ),
            ],
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
                          label: StatementsAnalyticsCopy.unlinkedLabel(context),
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
                              title: StatementsAnalyticsCopy.linkedRateLabel(
                                context,
                              ),
                              value: linkedPct,
                              subtitle: '${stats.total} movimientos analizados',
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
          showTitle: false,
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
          showTitle: false,
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
          showTitle: false,
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
        showTitle: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StatementsAnalyticsCopy.activitySubtitle(context),
                style: t.caption.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              AnalyticsHeatmap(days: days),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.activityActiveDaysLabel(
                        context),
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
    if (c.loadingSummary && !c.hasLoadedSummary) {
      sectionChildren.add(const AnalyticsSkeleton());
    } else {
      if (c.loadingSummary) {
        sectionChildren.add(const LinearProgressIndicator(minHeight: 2));
      }
      if (c.summaryError != null) {
        sectionChildren.add(
          Text(c.summaryError!, style: t.bodySmall.copyWith(color: cs.error)),
        );
      }
      if (widget.section == EnableBankingMenu.analyticsOverview) {
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
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useBottomSheet = constraints.maxWidth < 700;
        final appliedFilterCount = c.activeFilterCount;

        Future<void> openFilterSheet() => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (sheetContext) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: ListenableBuilder(
                  listenable: c,
                  builder: (_, __) => filterPanel(
                    onClose: () => Navigator.of(sheetContext).pop(),
                    contentWidth: MediaQuery.sizeOf(sheetContext).width - 28,
                  ),
                ),
              ),
            );

        return CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                minHeight: 52,
                maxHeight: 52,
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reportTitle(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (useBottomSheet)
                        _AnalyticsFilterButton(
                          activeCount: appliedFilterCount,
                          onPressed: openFilterSheet,
                        )
                      else
                        _AnalyticsFilterPopover(
                          activeCount: appliedFilterCount,
                          panelBuilder: (_) => ListenableBuilder(
                            listenable: c,
                            builder: (_, __) => filterPanel(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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

class _AnalyticsFilterButton extends StatelessWidget {
  const _AnalyticsFilterButton({
    required this.activeCount,
    required this.onPressed,
  });

  final int activeCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final active = activeCount > 0;
    return Tooltip(
      message: l.statementsFiltersTitle,
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: active ? cs.primary : cs.onSurfaceVariant,
            backgroundColor: active ? cs.primary.withValues(alpha: 0.08) : null,
            side: BorderSide(
              color: active
                  ? cs.primary.withValues(alpha: 0.45)
                  : cs.outlineVariant.withValues(alpha: 0.65),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                l.statementsFiltersTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsFilterPopover extends StatefulWidget {
  const _AnalyticsFilterPopover({
    required this.activeCount,
    required this.panelBuilder,
  });

  final int activeCount;
  final WidgetBuilder panelBuilder;

  @override
  State<_AnalyticsFilterPopover> createState() =>
      _AnalyticsFilterPopoverState();
}

class _AnalyticsFilterPopoverState extends State<_AnalyticsFilterPopover> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  @override
  void didUpdateWidget(covariant _AnalyticsFilterPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _removeEntry(notify: false);
    super.dispose();
  }

  void _toggle() => _entry == null ? _open() : _removeEntry();

  void _open() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (overlayContext) {
        final cs = Theme.of(overlayContext).colorScheme;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeEntry,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.escape):
                      _removeEntry,
                },
                child: Focus(
                  autofocus: true,
                  child: Material(
                    color: cs.surfaceContainer,
                    elevation: 4,
                    shadowColor: Colors.black.withValues(alpha: 0.18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.55),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      width: 304,
                      child: widget.panelBuilder(overlayContext),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_entry!);
    if (mounted) setState(() {});
  }

  void _removeEntry({bool notify = true}) {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
    if (notify && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
        link: _layerLink,
        child: _AnalyticsFilterButton(
          activeCount: widget.activeCount,
          onPressed: _toggle,
        ),
      );
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
    return SizedBox.expand(
      child: Material(
        elevation: overlapsContent ? 2 : 0,
        color: Theme.of(context).colorScheme.surface,
        child: child,
      ),
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
