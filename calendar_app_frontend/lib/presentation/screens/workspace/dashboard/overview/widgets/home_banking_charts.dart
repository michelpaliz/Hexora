import 'package:flutter/material.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_copy.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_widgets.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/services/statements/statements_api.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class HomeBankingCharts extends StatelessWidget {
  const HomeBankingCharts({
    super.key,
    required this.groupId,
    required this.onOpenBanking,
    required this.selectedChartIds,
    required this.onSelectionChanged,
  });

  final String groupId;
  final VoidCallback onOpenBanking;
  final Set<String> selectedChartIds;
  final void Function(String id, Map<String, dynamic>? chart)
      onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      key: ValueKey(groupId),
      create: (_) => StatementsAnalyticsController(
        api: StatementsApi(groupId: groupId),
        groupId: groupId,
        loadDerivedData: false,
      )..loadBatches(),
      child: _HomeBankingChartsContent(
        groupId: groupId,
        onOpenBanking: onOpenBanking,
        selectedChartIds: selectedChartIds,
        onSelectionChanged: onSelectionChanged,
      ),
    );
  }
}

class _HomeBankingChartsContent extends StatelessWidget {
  const _HomeBankingChartsContent({
    required this.groupId,
    required this.onOpenBanking,
    required this.selectedChartIds,
    required this.onSelectionChanged,
  });

  final String groupId;
  final VoidCallback onOpenBanking;
  final Set<String> selectedChartIds;
  final void Function(String id, Map<String, dynamic>? chart)
      onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StatementsAnalyticsController>();
    final localizations = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final isSpanish = localizations.localeName.startsWith('es');

    Widget chartCard({
      required String id,
      required String title,
      required Widget chart,
      required Map<String, dynamic> snapshot,
    }) =>
        Card(
          margin: EdgeInsets.zero,
          color: colors.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selectedChartIds.contains(id)
                  ? colors.primary
                  : colors.outlineVariant,
              width: selectedChartIds.contains(id) ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    FilterChip(
                      avatar: selectedChartIds.contains(id)
                          ? null
                          : Icon(LucideIcons.sparkles,
                              size: 14, color: colors.primary),
                      label: Text(selectedChartIds.contains(id)
                          ? (isSpanish ? 'Seleccionado' : 'Selected')
                          : (isSpanish ? 'Usar en chat' : 'Use in chat')),
                      selected: selectedChartIds.contains(id),
                      onSelected: (selected) => onSelectionChanged(
                        id,
                        selected ? snapshot : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                chart,
              ],
            ),
          ),
        );

    Widget chartContent() {
      if (controller.loadingBatches ||
          (controller.loadingSummary && !controller.hasLoadedSummary)) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      if (controller.summaryError != null && !controller.hasLoadedSummary) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.summaryError!,
                    style: TextStyle(color: colors.error),
                  ),
                ),
                IconButton(
                  onPressed: controller.fetchSummary,
                  tooltip: localizations.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        );
      }
      if (controller.batches.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isSpanish
                  ? 'Conecta o importa una cuenta bancaria para ver gráficos.'
                  : 'Connect or import a bank account to see charts.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }

      final yearlyRows = controller.years;
      final totals = controller.visibleTotals;
      final scope = <String, dynamic>{
        'groupId': groupId,
        'source': 'bank_statement_analytics',
        'period': 'all_imported_statement_years',
        'capturedAt': DateTime.now().toUtc().toIso8601String(),
      };
      final trendSnapshot = {
        ...scope,
        'id': 'bank_yearly_trend',
        'rows': yearlyRows
            .take(20)
            .map((row) => {
                  'year': row['year'],
                  'income': row['income'],
                  'expense': row['expense'],
                  'net': row['net'],
                  'count': row['count'],
                })
            .toList(),
      };
      final splitSnapshot = {
        ...scope,
        'id': 'bank_income_expense',
        'totals': {
          'income': totals.income,
          'expense': totals.expense,
          'net': totals.net,
          'count': totals.count,
        },
      };
      final volumeSnapshot = {
        ...scope,
        'id': 'bank_transaction_volume',
        'rows': controller.volumePoints
            .take(20)
            .map((point) => {
                  'label': point.label,
                  'count': point.count,
                  'absoluteMovement': point.absoluteMovement,
                })
            .toList(),
      };
      final trendChart = AnalyticsTrendChart(
        compact: true,
        rows: yearlyRows,
        labelBuilder: (row) => row['year']?.toString() ?? '-',
      );
      final splitChart = AnalyticsDonutChart(
        slices: [
          AnalyticsDonutSlice(
            label: localizations.statementsSummaryIncome,
            value: totals.income,
            color: const Color(0xFF2563EB),
            legendValue:
                StatementsFormatters.formatCurrency(context, totals.income),
            tooltipValue:
                StatementsFormatters.formatCurrency(context, totals.income),
          ),
          AnalyticsDonutSlice(
            label: localizations.statementsSummaryExpense,
            value: totals.expense,
            color: const Color(0xFF8B5CF6),
            legendValue:
                StatementsFormatters.formatCurrency(context, totals.expense),
            tooltipValue:
                StatementsFormatters.formatCurrency(context, totals.expense),
          ),
        ],
        centerLabel: localizations.statementsSummaryNet,
        centerValue: StatementsFormatters.formatCurrency(context, totals.net),
      );
      final volumeChart =
          AnalyticsVolumeChart(points: controller.volumePoints, compact: true);

      Widget metric(String label, String value, Color accent) => Container(
            constraints: const BoxConstraints(minWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
          );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            yearlyRows.isEmpty
                ? (isSpanish
                    ? 'Todos los datos importados'
                    : 'All imported data')
                : '${isSpanish ? 'Años con datos' : 'Years with data'}: ${yearlyRows.map((row) => row['year']).join(' · ')}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800
                ? 4
                : constraints.maxWidth >= 400
                    ? 2
                    : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(spacing: 12, runSpacing: 12, children: [
              SizedBox(
                  width: width,
                  child: metric(
                      localizations.statementsSummaryIncome,
                      StatementsFormatters.formatCurrency(
                          context, totals.income),
                      const Color(0xFF2563EB))),
              SizedBox(
                  width: width,
                  child: metric(
                      localizations.statementsSummaryExpense,
                      StatementsFormatters.formatCurrency(
                          context, totals.expense),
                      const Color(0xFF8B5CF6))),
              SizedBox(
                  width: width,
                  child: metric(
                      localizations.statementsSummaryNet,
                      StatementsFormatters.formatCurrency(context, totals.net),
                      totals.net < 0 ? colors.error : const Color(0xFF0D9488))),
              SizedBox(
                  width: width,
                  child: metric(
                      isSpanish ? 'Movimientos' : 'Transactions',
                      StatementsFormatters.formatCount(context, totals.count),
                      colors.onSurface)),
            ]);
          }),
          const SizedBox(height: 12),
          if (controller.loadingSummary)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (controller.summaryError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                isSpanish
                    ? 'No se pudo actualizar el resumen. Se muestran los últimos datos.'
                    : 'Could not refresh the summary. Showing the last loaded data.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.error),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final cardWidth =
                  wide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: wide ? constraints.maxWidth : cardWidth,
                    child: chartCard(
                      id: 'bank_yearly_trend',
                      title: isSpanish ? 'Evolución anual' : 'Yearly trends',
                      chart: trendChart,
                      snapshot: trendSnapshot,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: chartCard(
                      id: 'bank_income_expense',
                      title: StatementsAnalyticsCopy.splitTitle(context),
                      chart: splitChart,
                      snapshot: splitSnapshot,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: chartCard(
                      id: 'bank_transaction_volume',
                      title: StatementsAnalyticsCopy.volumeTitle(context),
                      chart: volumeChart,
                      snapshot: volumeSnapshot,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isSpanish ? 'Resumen bancario' : 'Banking overview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onOpenBanking,
              child: Text(isSpanish ? 'Ver análisis' : 'View analytics'),
            ),
          ],
        ),
        Text(
          isSpanish
              ? 'Selecciona gráficos para que Hexora los explique en el chat.'
              : 'Select charts for Hexora to explain in chat.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        chartContent(),
      ],
    );
  }
}
