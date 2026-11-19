import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
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
              legend: const Legend(
                  isVisible: true, position: LegendPosition.bottom),
              primaryXAxis: CategoryAxis(
                labelRotation: hasMonths ? 45 : 0,
                labelIntersectAction: hasMonths
                    ? AxisLabelIntersectAction.rotate45
                    : AxisLabelIntersectAction.hide,
              ),
              primaryYAxis: const NumericAxis(),
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
        primaryYAxis: const NumericAxis(),
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
        legend: const Legend(isVisible: true, position: LegendPosition.bottom),
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

enum _MerchantViewMode { chart, list }

/// Top merchants ("Top comercios") as a readable **horizontal** ranking.
///
/// Merchant names run down the vertical axis (no more overlapping horizontal
/// labels), amounts along the bottom with compact currency ticks, highest
/// first. A chart/list toggle swaps to a structured ranking (rank · name ·
/// amount · count). The old free-text block below the chart is gone. Totals
/// and ordering come straight from the controller — unchanged.
class TopMerchantsChart extends StatefulWidget {
  const TopMerchantsChart({
    super.key,
    required this.rows,
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.isExpense = true,
  });

  final List<Map<String, dynamic>> rows;
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  final bool isExpense;

  @override
  State<TopMerchantsChart> createState() => _TopMerchantsChartState();
}

class _TopMerchantsChartState extends State<TopMerchantsChart> {
  _MerchantViewMode _mode = _MerchantViewMode.chart;

  late final TooltipBehavior _tooltip = TooltipBehavior(
    enable: true,
    builder: (data, point, series, pointIndex, seriesIndex) {
      final p = data as _MerchantPoint;
      return _TooltipCard(
        title: widget.title,
        label: p.merchant,
        value: StatementsFormatters.formatCurrency(context, p.total),
        count: p.count.toInt(),
      );
    },
  );

  String _normalizeMerchant(String value) =>
      value.replaceAll(RegExp(r'\s+'), ' ').trim();

  List<_MerchantPoint> _points(List<Map<String, dynamic>> rows) => rows
      .map(
        (row) => _MerchantPoint(
          merchant: _normalizeMerchant(row['merchant']?.toString() ?? '-'),
          total: (row['total'] as num?) ?? 0,
          count: (row['count'] as num?) ?? 0,
        ),
      )
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final es = Localizations.localeOf(context).languageCode == 'es';

    if (widget.rows.isEmpty) {
      return AnalyticsStateMessage(message: l.statementsAnalyticsNoMerchants);
    }

    final visibleRows =
        widget.expanded ? widget.rows : widget.rows.take(10).toList();
    final points = _points(visibleRows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                es
                    ? '${widget.rows.length} comercios'
                    : '${widget.rows.length} merchants',
                style: t.caption.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            AnalyticsSegmented<_MerchantViewMode>(
              value: _mode,
              height: 30,
              onChanged: (m) => setState(() => _mode = m),
              segments: [
                AnalyticsSegment(
                  value: _MerchantViewMode.chart,
                  icon: Icons.bar_chart_rounded,
                  tooltip: es ? 'Gráfico' : 'Chart',
                ),
                AnalyticsSegment(
                  value: _MerchantViewMode.list,
                  icon: Icons.format_list_numbered_rounded,
                  tooltip: es ? 'Lista' : 'List',
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _mode == _MerchantViewMode.chart
              ? _buildChart(points)
              : _buildList(points),
        ),
        if (widget.rows.length > 10)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: widget.onToggle,
              child: Text(
                widget.expanded
                    ? l.statementsAnalyticsCollapse
                    : l.statementsAnalyticsExpand,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChart(List<_MerchantPoint> points) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    // Keep Gastos / Ingresos distinguishable without a rainbow of per-merchant
    // colors: expense uses the primary accent, income the success green.
    final barColor = widget.isExpense ? cs.primary : const Color(0xFF17B26A);
    // One fixed slot per bar so names never overlap; the area scrolls when the
    // ranking is taller than the available height.
    final chartHeight = (points.length * 34).clamp(180, 4000).toDouble();
    return LayoutBuilder(
      builder: (context, box) {
        final h = chartHeight < box.maxHeight ? box.maxHeight : chartHeight;
        return SingleChildScrollView(
          child: SizedBox(
            height: h,
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
              tooltipBehavior: _tooltip,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                maximumLabelWidth: 120,
                labelStyle: t.caption.copyWith(color: cs.onSurface),
              ),
              primaryYAxis: NumericAxis(
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                  dashArray: const [4, 4],
                ),
                axisLabelFormatter: (args) => ChartAxisLabel(
                  _compactAmount(context, args.value),
                  t.caption.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              series: <CartesianSeries<_MerchantPoint, String>>[
                BarSeries<_MerchantPoint, String>(
                  dataSource: points,
                  xValueMapper: (p, _) => p.merchant,
                  yValueMapper: (p, _) => p.total,
                  color: barColor,
                  width: 0.62,
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<_MerchantPoint> points) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: points.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: cs.outlineVariant.withValues(alpha: 0.35),
      ),
      itemBuilder: (context, i) {
        final p = points[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                child: Text(
                  '${i + 1}',
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: Tooltip(
                  message: p.merchant,
                  child: Text(
                    p.merchant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                StatementsFormatters.formatCurrency(context, p.total),
                style: t.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  es ? '${p.count.toInt()} mov.' : '${p.count.toInt()} txns',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.caption.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String _compactAmount(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toString();
  final es = Localizations.localeOf(context).languageCode == 'es';
  final formatted = NumberFormat.compact(locale: locale).format(value);
  return es ? '$formatted €' : formatted;
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
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = 4.0;
            final cellWidth = (constraints.maxWidth - (spacing * 6)) / 7;
            final cellHeight = (cellWidth * 0.38).clamp(40.0, 58.0).toDouble();
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                childAspectRatio: cellWidth / cellHeight,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final value = dayMetric(day);
                final opacity = maxValue <= 0
                    ? 0.08
                    : (0.14 + (value / maxValue) * 0.72)
                        .clamp(0.08, 0.92)
                        .toDouble();
                final label =
                    '${StatementsFormatters.formatDate(context, day.date)} · ${showAbsoluteMovement ? StatementsFormatters.formatCurrency(context, day.absoluteMovement) : '${day.count} mov.'}';
                return Tooltip(
                  message: label,
                  child: _AnalyticsHeatmapCell(
                    day: day.date.day,
                    color: cs.primary.withValues(
                      alpha: value == 0 ? 0.06 : opacity,
                    ),
                    borderColor: cs.outlineVariant.withValues(alpha: 0.3),
                    hoverBorderColor: cs.primary.withValues(alpha: 0.55),
                    textStyle: t.caption.copyWith(
                      color: value == 0 || opacity < 0.42
                          ? cs.onSurfaceVariant
                          : cs.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
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
            Text(
                StatementsAnalyticsCopy.activityWindowLabel(
                    context, days.length),
                style: t.caption),
          ],
        ),
      ],
    );
  }

  num dayMetric(StatementsAnalyticsHeatmapDay day) =>
      showAbsoluteMovement ? day.absoluteMovement : day.count;
}

class _AnalyticsHeatmapCell extends StatefulWidget {
  const _AnalyticsHeatmapCell({
    required this.day,
    required this.color,
    required this.borderColor,
    required this.hoverBorderColor,
    required this.textStyle,
  });

  final int day;
  final Color color;
  final Color borderColor;
  final Color hoverBorderColor;
  final TextStyle textStyle;

  @override
  State<_AnalyticsHeatmapCell> createState() => _AnalyticsHeatmapCellState();
}

class _AnalyticsHeatmapCellState extends State<_AnalyticsHeatmapCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hovered ? widget.hoverBorderColor : widget.borderColor,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(widget.day.toString(), style: widget.textStyle),
        ),
      );
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
    this.count,
  });

  final String title;
  final String label;
  final String value;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final es = Localizations.localeOf(context).languageCode == 'es';
    final countText =
        count == null ? '' : ' · ${count!} ${es ? 'mov.' : 'txns'}';
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.caption.copyWith(
                color: cs.surface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: t.bodySmall.copyWith(
                color: cs.surface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$value$countText',
              style: t.bodySmall.copyWith(color: cs.surface),
            ),
          ],
        ),
      ),
    );
  }
}

/// One segment of [AnalyticsSegmented].
class AnalyticsSegment<T> {
  const AnalyticsSegment({
    required this.value,
    this.label,
    this.icon,
    this.tooltip,
  });

  final T value;
  final String? label;
  final IconData? icon;
  final String? tooltip;
}

/// Compact pill segmented control (~34px) with a subtle blue selected state
/// and neutral inactive segments. Used for Gastos/Ingresos and chart/list.
class AnalyticsSegmented<T> extends StatelessWidget {
  const AnalyticsSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.height = 34,
  });

  final List<AnalyticsSegment<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: segments.map((s) {
          final selected = s.value == value;
          final fg = selected ? cs.onPrimary : cs.onSurfaceVariant;
          final seg = InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: () => onChanged(s.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? cs.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.icon != null) Icon(s.icon, size: 16, color: fg),
                  if (s.icon != null && s.label != null)
                    const SizedBox(width: 6),
                  if (s.label != null)
                    Text(
                      s.label!,
                      style: t.bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                ],
              ),
            ),
          );
          return s.tooltip != null
              ? Tooltip(message: s.tooltip!, child: seg)
              : seg;
        }).toList(),
      ),
    );
  }
}
