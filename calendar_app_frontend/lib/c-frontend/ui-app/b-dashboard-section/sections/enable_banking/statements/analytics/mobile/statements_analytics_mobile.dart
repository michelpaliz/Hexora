import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../statements_formatters.dart';
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
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AnalyticsFilterSheet(
        controller: ctx.read<StatementsAnalyticsController>(),
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
      return Center(
        child:
            Text(c.batchesError!, style: t.bodySmall.copyWith(color: cs.error)),
      );
    }
    if (c.batches.isEmpty) {
      return Center(
          child: Text(l.statementsAnalyticsNoBatches, style: t.bodySmall));
    }
    if (c.selectedBatchId == null) {
      return Center(
          child: Text(l.statementsAnalyticsNoSelection, style: t.bodySmall));
    }

    final yearOptions = c.years
        .map((y) => int.tryParse(y['year']?.toString() ?? ''))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();

    // ── Compact filter bar ───────────────────────────────────────────────────
    final filterBar = Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // All years chip
                  _FilterChip(
                    label: l.statementsAnalyticsAllYears,
                    selected: c.selectedYear == null,
                    onTap: () => c.setYear(null),
                  ),
                  const SizedBox(width: 6),
                  // Year chips
                  for (final y in yearOptions) ...[
                    _FilterChip(
                      label: y.toString(),
                      selected: c.selectedYear == y,
                      onTap: () => c.setYear(y),
                    ),
                    const SizedBox(width: 6),
                  ],
                  // Month chips (only if year selected)
                  if (c.selectedYear != null) ...[
                    const SizedBox(width: 4),
                    _FilterChip(
                      label: l.statementsAnalyticsAllMonths,
                      selected: c.selectedMonth == null,
                      onTap: () => c.setMonth(null),
                    ),
                    const SizedBox(width: 6),
                    for (int m = 1; m <= 12; m++) ...[
                      _FilterChip(
                        label: m.toString().padLeft(2, '0'),
                        selected: c.selectedMonth == m,
                        onTap: () => c.setMonth(m),
                      ),
                      if (m < 12) const SizedBox(width: 6),
                    ],
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            tooltip: l.statementsFiltersTitle,
            onPressed: () => _openFilterSheet(context),
          ),
        ],
      ),
    );

    final baseRows = c.selectedYear == null ? c.years : c.months;

    String labelBuilder(Map<String, dynamic> row) {
      final year = row['year']?.toString() ?? '-';
      final month = row['month']?.toString();
      if (c.selectedYear == null || month == null || month.isEmpty) return year;
      return month.padLeft(2, '0');
    }

    // ── Content ──────────────────────────────────────────────────────────────
    return Column(
      children: [
        filterBar,
        const Divider(height: 1),
        Expanded(
          child: c.loadingSummary
              ? const Center(child: AnalyticsSkeleton())
              : c.summaryError != null
                  ? Center(
                      child: Text(c.summaryError!,
                          style: t.bodySmall.copyWith(color: cs.error)),
                    )
                  : CustomScrollView(
                      slivers: [
                        // ── Trend chart ──────────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _SectionCard(
                              title: l.statementsAnalyticsTrends,
                              child: DefaultTabController(
                                length: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    TabBar(
                                      labelStyle: t.bodySmall,
                                      tabs: [
                                        Tab(
                                          text: l
                                              .statementsAnalyticsTotalsTab,
                                        ),
                                        Tab(
                                          text: l
                                              .statementsAnalyticsAverageTab,
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
                                            rows: _buildAverageRows(
                                                baseRows),
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
                            padding:
                                const EdgeInsets.fromLTRB(12, 12, 12, 0),
                            child: _SectionCard(
                              title: l.statementsAnalyticsTopMerchants,
                              child: DefaultTabController(
                                length: 2,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    TabBar(
                                      labelStyle: t.bodySmall,
                                      tabs: [
                                        Tab(
                                          text: l
                                              .statementsSummaryExpense,
                                        ),
                                        Tab(
                                          text: l.statementsSummaryIncome,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 320,
                                      child: TabBarView(
                                        children: [
                                          TopMerchantsChart(
                                            rows: c.topExpense,
                                            title: l.statementsSummaryExpense,
                                            expanded: _showAllExpense,
                                            onToggle: () => setState(() =>
                                                _showAllExpense =
                                                    !_showAllExpense),
                                          ),
                                          TopMerchantsChart(
                                            rows: c.topIncome,
                                            title: l.statementsSummaryIncome,
                                            expanded: _showAllIncome,
                                            onToggle: () => setState(() =>
                                                _showAllIncome =
                                                    !_showAllIncome),
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
                        // ── Summary totals ────────────────────────────────────
                        if (c.selectedYear != null &&
                            c.compareRows.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 0),
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

  List<Map<String, dynamic>> _buildAverageRows(
      List<Map<String, dynamic>> rows) {
    return rows.map((row) {
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
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      labelStyle: t.bodySmall.copyWith(fontSize: 11),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      showCheckmark: false,
    );
  }
}

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
        border:
            Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
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

    if (c.loadingCompare) return const Center(child: CircularProgressIndicator());
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
        final totals = c.periodMode ==
                StatementsAnalyticsPeriodMode.settlementWindow
            ? row.settlementTotals
            : row.calendarTotals;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.statementsAnalyticsMonth} $monthLabel',
                  style:
                      t.bodySmall.copyWith(fontWeight: FontWeight.w700),
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
                  value: StatementsFormatters.formatCurrency(
                      context, totals.net),
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

    final batchName = c.selectedBatchId == 'all' || c.selectedBatchId == null
        ? l.statementsAnalyticsAllBatches
        : (c.batches
                    .firstWhere(
                      (b) =>
                          (b['batchId'] ?? b['_id'] ?? b['id'])?.toString() ==
                          c.selectedBatchId,
                      orElse: () => {},
                    )[
                    'originalName'] ??
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
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
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
            // Top N
            Text(l.statementsAnalyticsTop,
                style: t.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
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
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 6),
            DropdownButtonFormField<StatementsAnalyticsPeriodMode>(
              initialValue: c.periodMode,
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
