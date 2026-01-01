import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../statements_formatters.dart';

class AnalyticsTrendChart extends StatelessWidget {
  const AnalyticsTrendChart({
    super.key,
    required this.rows,
    required this.labelBuilder,
  });

  final List<Map<String, dynamic>> rows;
  final String Function(Map<String, dynamic> row) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return Text(l.statementsAnalyticsNoData, style: t.bodySmall);
    }

    final points = rows.map((row) {
      return _TrendPoint(
        label: labelBuilder(row),
        income: (row['income'] as num?) ?? 0,
        expense: (row['expense'] as num?) ?? 0,
        net: (row['net'] as num?) ?? 0,
      );
    }).toList();

    final hasMonths = rows.any((row) => row['month'] != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 320,
          child: SfCartesianChart(
            legend: Legend(isVisible: true, position: LegendPosition.bottom),
            primaryXAxis: CategoryAxis(
              labelRotation: hasMonths ? 45 : 0,
              labelIntersectAction: hasMonths
                  ? AxisLabelIntersectAction.rotate45
                  : AxisLabelIntersectAction.hide,
            ),
            primaryYAxis: NumericAxis(),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (data, point, series, pointIndex, seriesIndex) {
                final p = data as _TrendPoint;
                final title = series.name ?? '';
                final value = switch (seriesIndex) {
                  0 => p.income,
                  1 => p.expense,
                  _ => p.net,
                };
                return _TooltipCard(
                  title: title,
                  label: p.label,
                  value: StatementsFormatters.formatCurrency(context, value),
                );
              },
            ),
            series: <CartesianSeries<_TrendPoint, String>>[
              ColumnSeries<_TrendPoint, String>(
                name: l.statementsSummaryIncome,
                dataSource: points,
                xValueMapper: (p, _) => p.label,
                yValueMapper: (p, _) => p.income,
              ),
              ColumnSeries<_TrendPoint, String>(
                name: l.statementsSummaryExpense,
                dataSource: points,
                xValueMapper: (p, _) => p.label,
                yValueMapper: (p, _) => p.expense,
              ),
              LineSeries<_TrendPoint, String>(
                name: l.statementsSummaryNet,
                dataSource: points,
                xValueMapper: (p, _) => p.label,
                yValueMapper: (p, _) => p.net,
                markerSettings: const MarkerSettings(isVisible: true),
              ),
            ],
          ),
        ),
        if (!hasMonths) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: points.map((p) {
              return _YearSummaryCard(point: p);
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class TopMerchantsChart extends StatelessWidget {
  const TopMerchantsChart({
    super.key,
    required this.rows,
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  final List<Map<String, dynamic>> rows;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return Text(l.statementsAnalyticsNoMerchants, style: t.bodySmall);
    }

    final visible = expanded ? rows : rows.take(10).toList();
    final points = visible.map((row) {
      return _MerchantPoint(
        merchant: _normalizeMerchant(row['merchant']?.toString() ?? '-'),
        total: (row['total'] as num?) ?? 0,
        count: (row['count'] as num?) ?? 0,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: SfCartesianChart(
            isTransposed: true,
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (data, point, series, pointIndex, seriesIndex) {
                final p = data as _MerchantPoint;
                return _TooltipCard(
                  title: title,
                  label: p.merchant,
                  value: StatementsFormatters.formatCurrency(context, p.total),
                );
              },
            ),
            primaryXAxis: CategoryAxis(
              labelIntersectAction: AxisLabelIntersectAction.hide,
            ),
            primaryYAxis: NumericAxis(),
            series: <CartesianSeries<_MerchantPoint, String>>[
              BarSeries<_MerchantPoint, String>(
                dataSource: points,
                xValueMapper: (p, _) => p.merchant,
                yValueMapper: (p, _) => p.total,
                dataLabelSettings: const DataLabelSettings(isVisible: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: points.map((p) {
                    return Text(
                      '${p.merchant} · ${StatementsFormatters.formatCurrency(context, p.total)} · ×${p.count.toInt()}',
                      style: t.caption,
                    );
                  }).toList(),
                ),
                if (rows.length > 10)
                  TextButton(
                    onPressed: onToggle,
                    child: Text(expanded
                        ? l.statementsAnalyticsCollapse
                        : l.statementsAnalyticsExpand),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _normalizeMerchant(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _TrendPoint {
  _TrendPoint({
    required this.label,
    required this.income,
    required this.expense,
    required this.net,
  });

  final String label;
  final num income;
  final num expense;
  final num net;
}

class _YearSummaryCard extends StatelessWidget {
  const _YearSummaryCard({required this.point});

  final _TrendPoint point;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(point.label,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.statementsSummaryIncome}: ${StatementsFormatters.formatCurrency(context, point.income)}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context)!.statementsSummaryExpense}: ${StatementsFormatters.formatCurrency(context, point.expense)}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context)!.statementsSummaryNet}: ${StatementsFormatters.formatCurrency(context, point.net)}',
            style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MerchantPoint {
  _MerchantPoint({
    required this.merchant,
    required this.total,
    required this.count,
  });

  final String merchant;
  final num total;
  final num count;
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.title,
    required this.label,
    required this.value,
  });

  final String title;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: t.bodySmall.copyWith(
                color: cs.surface,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text(
            '$label · $value',
            style: t.bodySmall.copyWith(color: cs.surface),
          ),
        ],
      ),
    );
  }
}
