import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../statements_formatters.dart';
import 'statements_analytics_controller.dart';
import 'statements_analytics_copy.dart';

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
    final l = AppLocalizations.of(context)!;
    if (rows.isEmpty) {
      return AnalyticsStateMessage(message: l.statementsAnalyticsNoData);
    }

    final points = rows
        .map(
          (row) => _TrendPoint(
            label: labelBuilder(row),
            income: (row['income'] as num?) ?? 0,
            expense: (row['expense'] as num?) ?? 0,
            net: (row['net'] as num?) ?? 0,
          ),
        )
        .toList(growable: false);

    final hasMonths = rows.any((row) => row['month'] != null);
    return SingleChildScrollView(
      child: Column(
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
              children: points.map((p) => _YearSummaryCard(point: p)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class AnalyticsVolumeChart extends StatelessWidget {
  const AnalyticsVolumeChart({
    super.key,
    required this.points,
  });

  final List<StatementsAnalyticsVolumePoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return AnalyticsStateMessage(
        message: StatementsAnalyticsCopy.noEntriesLabel(context),
      );
    }
    final daily = points.first.daily;
    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: daily ? 55 : 0,
          labelIntersectAction: daily
              ? AxisLabelIntersectAction.rotate45
              : AxisLabelIntersectAction.hide,
        ),
        primaryYAxis: NumericAxis(),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            final p = data as StatementsAnalyticsVolumePoint;
            return _TooltipCard(
              title: StatementsAnalyticsCopy.volumeTitle(context),
              label: p.label,
              value:
                  '${StatementsFormatters.formatCount(context, p.count)} movimientos',
            );
          },
        ),
        series: <CartesianSeries<StatementsAnalyticsVolumePoint, String>>[
          if (daily)
            LineSeries<StatementsAnalyticsVolumePoint, String>(
              dataSource: points,
              xValueMapper: (point, _) => point.label,
              yValueMapper: (point, _) => point.count,
              markerSettings: const MarkerSettings(isVisible: true),
              name: StatementsAnalyticsCopy.volumeTitle(context),
            )
          else
            ColumnSeries<StatementsAnalyticsVolumePoint, String>(
              dataSource: points,
              xValueMapper: (point, _) => point.label,
              yValueMapper: (point, _) => point.count,
              name: StatementsAnalyticsCopy.volumeTitle(context),
            ),
        ],
      ),
    );
  }
}

class AnalyticsDonutChart extends StatelessWidget {
  const AnalyticsDonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
  });

  final List<AnalyticsDonutSlice> slices;
  final String centerLabel;
  final String centerValue;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    if (slices.isEmpty || slices.every((slice) => slice.value <= 0)) {
      return AnalyticsStateMessage(
        message: StatementsAnalyticsCopy.noEntriesLabel(context),
      );
    }
    return SizedBox(
      height: 280,
      child: SfCircularChart(
        legend: Legend(isVisible: true, position: LegendPosition.bottom),
        annotations: [
          CircularChartAnnotation(
            widget: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(centerLabel, style: t.caption),
                const SizedBox(height: 4),
                Text(
                  centerValue,
                  style: t.titleLarge.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            final slice = data as AnalyticsDonutSlice;
            return _TooltipCard(
              title: centerLabel,
              label: slice.label,
              value: slice.tooltipValue,
            );
          },
        ),
        series: <CircularSeries<AnalyticsDonutSlice, String>>[
          DoughnutSeries<AnalyticsDonutSlice, String>(
            dataSource: slices,
            xValueMapper: (slice, _) => slice.label,
            yValueMapper: (slice, _) => slice.value,
            pointColorMapper: (slice, _) => slice.color,
            dataLabelMapper: (slice, _) => slice.legendValue,
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            radius: '82%',
            innerRadius: '66%',
          ),
        ],
      ),
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
      return AnalyticsStateMessage(message: l.statementsAnalyticsNoMerchants);
    }

    final visible = expanded ? rows : rows.take(10).toList();
    final points = visible
        .map(
          (row) => _MerchantPoint(
            merchant: _normalizeMerchant(row['merchant']?.toString() ?? '-'),
            total: (row['total'] as num?) ?? 0,
            count: (row['count'] as num?) ?? 0,
          ),
        )
        .toList(growable: false);

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

class AnalyticsMetricCard extends StatelessWidget {
  const AnalyticsMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 220,
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
            Text(subtitle!, style: t.caption),
          ],
        ],
      ),
    );
  }
}

class AnalyticsHeatmap extends StatelessWidget {
  const AnalyticsHeatmap({
    super.key,
    required this.days,
    this.showAbsoluteMovement = false,
  });

  final List<StatementsAnalyticsHeatmapDay> days;
  final bool showAbsoluteMovement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (days.isEmpty) {
      return AnalyticsStateMessage(
        message: StatementsAnalyticsCopy.noEntriesLabel(context),
      );
    }
    final maxValue = days.fold<num>(
      0,
      (max, day) => dayMetric(day) > max ? dayMetric(day) : max,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final value = dayMetric(day);
            final opacity = maxValue <= 0
                ? 0.08
                : (0.14 + (value / maxValue) * 0.72).clamp(0.08, 0.92);
            final label =
                '${StatementsFormatters.formatDate(context, day.date)} · ${showAbsoluteMovement ? StatementsFormatters.formatCurrency(context, day.absoluteMovement) : '${day.count} mov.'}';
            return Tooltip(
              message: label,
              child: Container(
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: value == 0 ? 0.06 : opacity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    day.date.day.toString(),
                    style: t.caption.copyWith(
                      color: value == 0 ? cs.onSurfaceVariant : cs.onPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              showAbsoluteMovement
                  ? StatementsAnalyticsCopy.activityMovementLabel(context)
                  : StatementsAnalyticsCopy.activityCountLabel(context),
              style: t.caption,
            ),
            const Spacer(),
            Text(StatementsAnalyticsCopy.activityWindowLabel(context, days.length),
                style: t.caption),
          ],
        ),
      ],
    );
  }

  num dayMetric(StatementsAnalyticsHeatmapDay day) =>
      showAbsoluteMovement ? day.absoluteMovement : day.count;
}

class AnalyticsStatusBadge extends StatelessWidget {
  const AnalyticsStatusBadge({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: t.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AnalyticsStateMessage extends StatelessWidget {
  const AnalyticsStateMessage({
    super.key,
    required this.message,
    this.icon = Icons.insights_outlined,
    this.color,
  });

  final String message;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final resolved = color ?? cs.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: resolved),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: t.bodySmall.copyWith(color: resolved),
            ),
          ),
        ],
      ),
    );
  }
}

class AnalyticsDonutSlice {
  const AnalyticsDonutSlice({
    required this.label,
    required this.value,
    required this.color,
    required this.legendValue,
    required this.tooltipValue,
  });

  final String label;
  final num value;
  final Color color;
  final String legendValue;
  final String tooltipValue;
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
    final l = AppLocalizations.of(context)!;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(point.label,
              style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '${l.statementsSummaryIncome}: ${StatementsFormatters.formatCurrency(context, point.income)}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${l.statementsSummaryExpense}: ${StatementsFormatters.formatCurrency(context, point.expense)}',
            style: t.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '${l.statementsSummaryNet}: ${StatementsFormatters.formatCurrency(context, point.net)}',
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
        color: cs.onSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.bodySmall.copyWith(
              color: cs.surface,
              fontWeight: FontWeight.w700,
            ),
          ),
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
