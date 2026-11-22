import 'package:flutter/material.dart';
import 'package:hexora/theme/motion/hexora_motion.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../statements_formatters.dart';
import '../statements_analytics_copy.dart';
import '../statements_analytics_controller.dart';
import '../statements_analytics_view.dart' show AnalyticsSkeleton;
import '../statements_analytics_widgets.dart';

class StatementsMobileAnalyticsView extends StatefulWidget {
  const StatementsMobileAnalyticsView({super.key});

  @override
  State<StatementsMobileAnalyticsView> createState() =>
      _StatementsMobileAnalyticsViewState();
}

class _StatementsMobileAnalyticsViewState
    extends State<StatementsMobileAnalyticsView>
    with AutomaticKeepAliveClientMixin {
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

  void _openFilterSheet(BuildContext context) {
    final controller = context.read<StatementsAnalyticsController>();
    showModalBottomSheet<void>(
      sheetAnimationStyle: HexoraMotion.sheetStyle(context),
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (_, __) => SingleChildScrollView(
          child: _AnalyticsFilterSheet(controller: controller),
        ),
      ),
    );
  }

  Widget _retryState(
    BuildContext context,
    String message,
    VoidCallback onRetry,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.watch<StatementsAnalyticsController>();
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (c.loadingBatches) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.batchesError != null) {
      return _retryState(context, c.batchesError!, c.loadBatches);
    }
    if (c.batches.isEmpty) {
      return Center(
          child: Text(l.statementsAnalyticsNoBatches, style: t.bodySmall));
    }
    if (c.selectedBatchId == null) {
      return Center(
          child: Text(l.statementsAnalyticsNoSelection, style: t.bodySmall));
    }

    final filterBar = Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.statementsAnalyticsTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: l.statementsFiltersTitle,
            child: SizedBox(
              height: 34,
              child: OutlinedButton(
                onPressed: () => _openFilterSheet(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text(l.statementsFiltersTitle),
                    if (c.activeFilterCount > 0) ...[
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
                          '${c.activeFilterCount}',
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
          ),
        ],
      ),
    );

    final baseRows = c.trendRows;

    String labelBuilder(Map<String, dynamic> row) {
      final year = row['year']?.toString() ?? '-';
      final month = row['month']?.toString();
      if (c.selectedYear == null || month == null || month.isEmpty) return year;
      return month.padLeft(2, '0');
    }

    Widget buildOverviewSection() {
      final totals = c.visibleTotals;
      return _SectionCard(
        title: StatementsAnalyticsCopy.billableOverviewLabel(context),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            AnalyticsMetricCard(
              title: l.statementsSummaryIncome,
              value:
                  StatementsFormatters.formatCurrency(context, totals.income),
              subtitle: l.statementsEntryCount(totals.count.toString()),
              icon: Icons.south_west_rounded,
            ),
            AnalyticsMetricCard(
              title: l.statementsSummaryExpense,
              value:
                  StatementsFormatters.formatCurrency(context, totals.expense),
              icon: Icons.north_east_rounded,
            ),
            AnalyticsMetricCard(
              title: l.statementsSummaryNet,
              value: StatementsFormatters.formatCurrency(context, totals.net),
              icon: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),
      );
    }

    Widget buildSplitSection() {
      final totals = c.visibleTotals;
      return _SectionCard(
        title: StatementsAnalyticsCopy.splitTitle(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              StatementsAnalyticsCopy.splitSubtitle(context),
              style: t.bodySmall,
            ),
            const SizedBox(height: 10),
            AnalyticsDonutChart(
              slices: [
                AnalyticsDonutSlice(
                  label: l.statementsSummaryIncome,
                  value: totals.income,
                  color: const Color(0xFF2E7D32),
                  legendValue: StatementsFormatters.formatCurrency(
                      context, totals.income),
                  tooltipValue: StatementsFormatters.formatCurrency(
                      context, totals.income),
                ),
                AnalyticsDonutSlice(
                  label: l.statementsSummaryExpense,
                  value: totals.expense,
                  color: const Color(0xFFC62828),
                  legendValue: StatementsFormatters.formatCurrency(
                    context,
                    totals.expense,
                  ),
                  tooltipValue: StatementsFormatters.formatCurrency(
                    context,
                    totals.expense,
                  ),
                ),
              ],
              centerLabel: l.statementsSummaryNet,
              centerValue:
                  StatementsFormatters.formatCurrency(context, totals.net),
            ),
          ],
        ),
      );
    }

    Widget buildVolumeSection() => _SectionCard(
          title: StatementsAnalyticsCopy.volumeTitle(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                StatementsAnalyticsCopy.volumeSubtitle(context),
                style: t.bodySmall,
              ),
              const SizedBox(height: 10),
              AnalyticsVolumeChart(points: c.volumePoints),
            ],
          ),
        );

    Widget buildTicketSection() {
      if (c.loadingEntries) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.ticketTitle(context),
          child: const AnalyticsSkeleton(),
        );
      }
      if (c.entriesError != null) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.ticketTitle(context),
          child: AnalyticsStateMessage(
            message: c.entriesError!,
            icon: Icons.error_outline,
            color: cs.error,
          ),
        );
      }
      final stats = c.ticketStats;
      return _SectionCard(
        title: StatementsAnalyticsCopy.ticketTitle(context),
        child: stats == null
            ? AnalyticsStateMessage(
                message: StatementsAnalyticsCopy.noEntriesLabel(context),
              )
            : Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.averageIncomeLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.averageIncome,
                    ),
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.averageExpenseLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.averageExpense,
                    ),
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.largestIncomeLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.largestIncome,
                    ),
                  ),
                  AnalyticsMetricCard(
                    title: StatementsAnalyticsCopy.largestExpenseLabel(context),
                    value: StatementsFormatters.formatCurrency(
                      context,
                      stats.largestExpense,
                    ),
                  ),
                  AnalyticsMetricCard(
                    title:
                        StatementsAnalyticsCopy.totalTransactionsLabel(context),
                    value: stats.transactionCount.toString(),
                  ),
                ],
              ),
      );
    }

    Widget buildLinkedSection() {
      if (c.loadingEntries) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.linkedTitle(context),
          child: const AnalyticsSkeleton(),
        );
      }
      if (c.entriesError != null) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.linkedTitle(context),
          child: AnalyticsStateMessage(
            message: c.entriesError!,
            icon: Icons.error_outline,
            color: cs.error,
          ),
        );
      }
      final stats = c.linkStats;
      return _SectionCard(
        title: StatementsAnalyticsCopy.linkedTitle(context),
        child: stats == null
            ? AnalyticsStateMessage(
                message: StatementsAnalyticsCopy.noEntriesLabel(context),
              )
            : AnalyticsDonutChart(
                slices: [
                  AnalyticsDonutSlice(
                    label: StatementsAnalyticsCopy.linkedLabel(context),
                    value: stats.linkedCount,
                    color: const Color(0xFF1565C0),
                    legendValue: stats.linkedCount.toString(),
                    tooltipValue: stats.linkedCount.toString(),
                  ),
                  AnalyticsDonutSlice(
                    label: StatementsAnalyticsCopy.unlinkedLabel(context),
                    value: stats.unlinkedCount,
                    color: const Color(0xFFEF6C00),
                    legendValue: stats.unlinkedCount.toString(),
                    tooltipValue: stats.unlinkedCount.toString(),
                  ),
                ],
                centerLabel: StatementsAnalyticsCopy.linkedRateLabel(context),
                centerValue:
                    '${StatementsFormatters.formatAmount(context, stats.linkedRatio * 100)}%',
              ),
      );
    }

    Widget buildActivitySection() {
      if (c.loadingEntries) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.activityTitle(context),
          child: const AnalyticsSkeleton(),
        );
      }
      if (c.entriesError != null) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.activityTitle(context),
          child: AnalyticsStateMessage(
            message: c.entriesError!,
            icon: Icons.error_outline,
            color: cs.error,
          ),
        );
      }
      return _SectionCard(
        title: StatementsAnalyticsCopy.activityTitle(context),
        child: AnalyticsHeatmap(days: c.heatmapDays),
      );
    }

    Widget buildStatusSection() {
      if (c.loadingStatus) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.statusTitle(context),
          child: const AnalyticsSkeleton(),
        );
      }
      if (c.statusError != null) {
        return _SectionCard(
          title: StatementsAnalyticsCopy.statusTitle(context),
          child: AnalyticsStateMessage(
            message: c.statusError!,
            icon: Icons.error_outline,
            color: cs.error,
          ),
        );
      }
      final status = c.statusSnapshot;
      final badgeColor = status == null
          ? cs.onSurfaceVariant
          : (status.mixed
              ? cs.tertiary
              : (status.stale ? cs.error : const Color(0xFF2E7D32)));
      final badgeLabel = status == null
          ? '-'
          : (status.mixed
              ? StatementsAnalyticsCopy.mixedLabel(context)
              : (status.stale
                  ? StatementsAnalyticsCopy.staleLabel(context)
                  : StatementsAnalyticsCopy.freshLabel(context)));
      return _SectionCard(
        title: StatementsAnalyticsCopy.statusTitle(context),
        child: status == null
            ? AnalyticsStateMessage(
                message: StatementsAnalyticsCopy.noStatusLabel(context),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnalyticsStatusBadge(label: badgeLabel, color: badgeColor),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      AnalyticsMetricCard(
                        title: StatementsAnalyticsCopy.lastTransactionLabel(
                            context),
                        value: status.lastDate == null
                            ? '-'
                            : StatementsFormatters.formatDate(
                                context,
                                status.lastDate,
                              ),
                      ),
                      AnalyticsMetricCard(
                        title: StatementsAnalyticsCopy.daysSinceLabel(context),
                        value: status.daysSince?.toString() ?? '-',
                      ),
                    ],
                  ),
                ],
              ),
      );
    }

    // ── Content ──────────────────────────────────────────────────────────────
    return Column(
      children: [
        filterBar,
        const Divider(height: 1),
        Expanded(
          child: c.loadingSummary && !c.hasLoadedSummary
              ? const Center(child: AnalyticsSkeleton())
              : c.summaryError != null && !c.hasLoadedSummary
                  ? _retryState(context, c.summaryError!, c.fetchSummary)
                  : CustomScrollView(
                      slivers: [
                        if (c.loadingSummary)
                          const SliverToBoxAdapter(
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        if (c.summaryError != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                              child: Text(
                                c.summaryError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error,
                                    ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildOverviewSection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildSplitSection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildVolumeSection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildTicketSection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildLinkedSection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildActivitySection(),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: buildStatusSection(),
                          ),
                        ),
                        // ── Trend chart ──────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _SectionCard(
                              title: l.statementsAnalyticsTrends,
                              child: DefaultTabController(
                                length: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TabBar(
                                      labelStyle: t.bodySmall,
                                      tabs: [
                                        Tab(
                                          text: l.statementsAnalyticsTotalsTab,
                                        ),
                                        Tab(
                                          text: l.statementsAnalyticsAverageTab,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 280,
                                      child: TabBarView(
                                        children: [
                                          AnalyticsTrendChart(
                                            rows: baseRows,
                                            labelBuilder: labelBuilder,
                                          ),
                                          AnalyticsTrendChart(
                                            rows: c.averageTrendRows,
                                            labelBuilder: labelBuilder,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Top merchants ─────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _SectionCard(
                              title: l.statementsAnalyticsTopMerchants,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnalyticsSegmented<int>(
                                      value: _merchantTab,
                                      height: 32,
                                      onChanged: (v) =>
                                          setState(() => _merchantTab = v),
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
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 320,
                                    child: TopMerchantsChart(
                                      key: ValueKey(
                                          'top-merchants-m-$_merchantTab'),
                                      rows: _merchantTab == 0
                                          ? c.topExpense
                                          : c.topIncome,
                                      title: _merchantTab == 0
                                          ? l.statementsSummaryExpense
                                          : l.statementsSummaryIncome,
                                      isExpense: _merchantTab == 0,
                                      expanded: _merchantTab == 0
                                          ? _showAllExpense
                                          : _showAllIncome,
                                      onToggle: () => setState(() {
                                        if (_merchantTab == 0) {
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
                          ),
                        ),
                        // ── Summary totals ────────────────────────────────────
                        if (c.selectedYear != null && c.compareRows.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                              child: _SectionCard(
                                title: l.statementsAnalyticsCompareTitle,
                                child: _MobileComparisonSection(
                                  controller: c,
                                ),
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 24),
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MobileComparisonSection extends StatelessWidget {
  const _MobileComparisonSection({required this.controller});

  final StatementsAnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    if (c.loadingCompare) {
      return const Center(child: CircularProgressIndicator());
    }
    if (c.compareError != null) {
      return Text(c.compareError!,
          style: t.bodySmall.copyWith(color: cs.error));
    }
    if (c.compareRows.isEmpty) {
      return Text(l.statementsAnalyticsNoData, style: t.bodySmall);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: c.compareRows.map((row) {
        final monthLabel = row.month.toString().padLeft(2, '0');
        final totals =
            c.periodMode == StatementsAnalyticsPeriodMode.settlementWindow
                ? row.settlementTotals
                : row.calendarTotals;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.statementsAnalyticsMonth} $monthLabel',
                  style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _TotalRow(
                        label: l.statementsSummaryIncome,
                        value: StatementsFormatters.formatCurrency(
                            context, totals.income),
                        color: const Color(0xFF1565C0),
                        t: t,
                      ),
                    ),
                    Expanded(
                      child: _TotalRow(
                        label: l.statementsSummaryExpense,
                        value: StatementsFormatters.formatCurrency(
                            context, totals.expense),
                        color: const Color(0xFFC62828),
                        t: t,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _TotalRow(
                  label: l.statementsSummaryNet,
                  value:
                      StatementsFormatters.formatCurrency(context, totals.net),
                  color: cs.onSurface,
                  t: t,
                  bold: true,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    required this.color,
    required this.t,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color color;
  final AppTypography t;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: t.bodySmall.copyWith(fontSize: 11),
        ),
        Text(
          value,
          style: t.bodySmall.copyWith(
            fontSize: 11,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

class _AnalyticsFilterSheet extends StatelessWidget {
  const _AnalyticsFilterSheet({required this.controller});

  final StatementsAnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final availableYears = c.years
        .map((row) => int.tryParse(row['year']?.toString() ?? ''))
        .whereType<int>()
        .toSet()
        .toList();
    if (c.selectedYear != null) availableYears.add(c.selectedYear!);
    if (availableYears.isEmpty) {
      availableYears.addAll(
        List<int>.generate(6, (index) => DateTime.now().year - index),
      );
    }
    availableYears.sort();
    final compareOptions = <StatementsAnalyticsCompareMode, String>{
      StatementsAnalyticsCompareMode.both: l.statementsAnalyticsCompareBoth,
      StatementsAnalyticsCompareMode.calendarOnly:
          l.statementsAnalyticsCompareCalendar,
      StatementsAnalyticsCompareMode.settlementOnly:
          l.statementsAnalyticsCompareSettlement,
      StatementsAnalyticsCompareMode.delta: l.statementsAnalyticsCompareDelta,
    };

    final batchName = c.selectedBatchId == 'all' || c.selectedBatchId == null
        ? l.statementsAnalyticsAllBatches
        : (c.batches.firstWhere(
                  (b) =>
                      (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ==
                      c.selectedBatchId,
                  orElse: () => {},
                )['originalName'] ??
                c.selectedBatchId)
            .toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l.statementsFiltersTitle,
                    style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: Navigator.of(context).pop,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            // Batch
            Text(l.statementsAnalyticsBatch,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: c.selectedBatchId,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                isDense: true,
                hintText: batchName,
              ),
              items: [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(l.statementsAnalyticsAllBatches,
                      overflow: TextOverflow.ellipsis),
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
                }),
              ],
              onChanged: (v) => c.selectBatch(v),
            ),
            const SizedBox(height: 16),
            Text(l.statementsFilterYear,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: c.selectedYear,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l.statementsAnalyticsAllYears),
                ),
                ...availableYears.map(
                  (year) => DropdownMenuItem(
                    value: year,
                    child: Text(year.toString()),
                  ),
                ),
              ],
              onChanged: c.setYear,
            ),
            const SizedBox(height: 16),
            Text(l.statementsAnalyticsMonth,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: c.selectedMonth,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l.statementsAnalyticsAllMonths),
                ),
                ...List<int>.generate(12, (index) => index + 1).map(
                  (month) => DropdownMenuItem(
                    value: month,
                    child: Text(month.toString().padLeft(2, '0')),
                  ),
                ),
              ],
              onChanged: c.selectedYear == null ? null : c.setMonth,
            ),
            const SizedBox(height: 16),
            // Top N
            Text(l.statementsAnalyticsTop,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int>(
              initialValue: c.top,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [5, 10, 20, 50]
                  .map((v) =>
                      DropdownMenuItem(value: v, child: Text(v.toString())))
                  .toList(),
              onChanged: (v) {
                if (v != null) c.setTop(v);
              },
            ),
            const SizedBox(height: 16),
            // Period mode
            Text(l.statementsAnalyticsMode,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<StatementsAnalyticsPeriodMode>(
              initialValue: c.periodMode,
              itemHeight: null,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
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
                if (v != null) c.setPeriodMode(v);
              },
            ),
            const SizedBox(height: 16),
            if (c.periodMode ==
                StatementsAnalyticsPeriodMode.settlementWindow) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: c.settlementStartDay,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.statementsAnalyticsSettlementStart,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: List<int>.generate(31, (index) => index + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text(day.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) c.setSettlementStartDay(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: c.settlementEndDay,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.statementsAnalyticsSettlementEnd,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: List<int>.generate(31, (index) => index + 1)
                          .map((day) => DropdownMenuItem(
                                value: day,
                                child: Text(day.toString()),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) c.setSettlementEndDay(value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            Text(l.statementsAnalyticsCompareMode,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<StatementsAnalyticsCompareMode>(
              initialValue: c.compareMode,
              isExpanded: true,
              style: t.bodyMedium,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: compareOptions.entries
                  .map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) c.setCompareMode(value);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: Navigator.of(context).pop,
                child: Text(l.dialogClose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
