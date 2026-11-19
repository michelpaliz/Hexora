import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/clients/client_invoice_stats.dart';
import 'package:hexora/services/clients/client_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ClientInvoiceStatsCard extends StatefulWidget {
  final GroupClient client;

  const ClientInvoiceStatsCard({
    super.key,
    required this.client,
  });

  @override
  State<ClientInvoiceStatsCard> createState() => _ClientInvoiceStatsCardState();
}

class _ClientInvoiceStatsCardState extends State<ClientInvoiceStatsCard> {
  final ClientsApi _clientsApi = ClientsApi();

  late final TooltipBehavior _tooltipBehavior;

  int _selectedMonths = 12;
  bool _loading = true;
  String? _error;
  ClientInvoiceStats? _stats;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      canShowMarker: false,
      builder: (
        dynamic data,
        dynamic point,
        dynamic series,
        int pointIndex,
        int seriesIndex,
      ) {
        final chartPoint = data as _ClientInvoiceChartPoint;
        return _InvoiceStatsTooltip(
          month: chartPoint.month,
          monthLabel: chartPoint.label,
        );
      },
    );
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant ClientInvoiceStatsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.client.id != widget.client.id) {
      _selectedMonths = 12;
      _stats = null;
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await _clientsApi.getInvoiceStats(
        widget.client.id,
        months: _selectedMonths,
      );
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeRange(int months) async {
    if (_selectedMonths == months) return;
    setState(() => _selectedMonths = months);
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadStats);
    }

    final stats = _stats;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final currency = NumberFormat.currency(
      locale: locale,
      symbol: '€',
      decimalDigits: 2,
    );
    final compactCurrency = NumberFormat.compactCurrency(
      locale: locale,
      symbol: '€',
    );
    final materialLocalizations = MaterialLocalizations.of(context);
    final points = stats.months
        .map(
          (month) => _ClientInvoiceChartPoint(
            label: _formatMonthLabel(month.month, locale),
            month: month,
          ),
        )
        .toList(growable: false);
    final yMaximum = _chartMaximum(points);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSpanish ? 'Facturación mensual' : 'Monthly billing',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              _RangeSelector(
                selectedMonths: _selectedMonths,
                isSpanish: isSpanish,
                onSelected: _changeRange,
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _loading ? null : _loadStats,
                tooltip: isSpanish ? 'Actualizar gráfico' : 'Refresh chart',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _InvoiceSummaryStrip(
            items: [
              _SummaryItem(
                label: isSpanish ? 'Total emitido' : 'Issued total',
                value: currency.format(stats.summary.issuedTotal),
                emphasized: true,
              ),
              _SummaryItem(
                label: isSpanish ? 'Emitidas' : 'Issued',
                value: '${stats.summary.issuedCount}',
              ),
              _SummaryItem(
                label: isSpanish ? 'Borradores' : 'Drafts',
                value: '${stats.summary.draftCount}',
              ),
              _SummaryItem(
                label: isSpanish ? 'Anuladas' : 'Voided',
                value: '${stats.summary.voidCount}',
              ),
              _SummaryItem(
                label: isSpanish ? 'Última emitida' : 'Last issued',
                value: stats.summary.lastIssuedAt == null
                    ? (isSpanish ? 'Sin emitidas' : 'None issued')
                    : materialLocalizations
                        .formatShortDate(stats.summary.lastIssuedAt!.toLocal()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxWidth >= 720 ? 300.0 : 280.0;
              if (!stats.hasAnyMonthlyActivity) {
                return SizedBox(
                  height: chartHeight,
                  child: const Center(child: _InvoiceStatsEmptyState()),
                );
              }
              return SizedBox(
                height: chartHeight,
                child: Semantics(
                  label: isSpanish
                      ? 'Facturación emitida por mes'
                      : 'Issued billing by month',
                  child: SfCartesianChart(
                    plotAreaBorderWidth: 0,
                    tooltipBehavior: _tooltipBehavior,
                    margin: const EdgeInsets.fromLTRB(0, 6, 4, 0),
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelRotation: points.length > 12 ? -45 : 0,
                      axisLine: AxisLine(
                        color: cs.outlineVariant.withValues(alpha: 0.45),
                      ),
                      labelStyle: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      minimum: 0,
                      maximum: yMaximum,
                      majorTickLines: const MajorTickLines(size: 0),
                      axisLine: const AxisLine(width: 0),
                      numberFormat: compactCurrency,
                      labelStyle: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      majorGridLines: MajorGridLines(
                        width: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.13),
                      ),
                    ),
                    series: <CartesianSeries<_ClientInvoiceChartPoint, String>>[
                      ColumnSeries<_ClientInvoiceChartPoint, String>(
                        dataSource: points,
                        xValueMapper: (point, _) => point.label,
                        yValueMapper: (point, _) => point.month.issuedTotal,
                        color: cs.primary,
                        width: points.length > 12 ? 0.72 : 0.58,
                        borderRadius: BorderRadius.circular(6),
                        enableTooltip: true,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatMonthLabel(String rawMonth, String locale) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(rawMonth);
    if (match == null) return rawMonth;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    if (year == null || month == null) return rawMonth;

    return DateFormat('MMM yy', locale)
        .format(DateTime(year, month))
        .replaceAll('.', '');
  }

  double _chartMaximum(List<_ClientInvoiceChartPoint> points) {
    final largest = points.fold<double>(
      0,
      (current, point) =>
          point.month.issuedTotal > current ? point.month.issuedTotal : current,
    );
    if (largest <= 0) return 1;

    final target = largest * 1.12;
    final magnitude = _powerOfTen(target);
    final normalized = target / magnitude;
    final rounded = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return rounded * magnitude;
  }

  double _powerOfTen(double value) {
    var magnitude = 1.0;
    while (value / magnitude >= 10) {
      magnitude *= 10;
    }
    while (value / magnitude < 1) {
      magnitude /= 10;
    }
    return magnitude;
  }
}

class _ClientInvoiceChartPoint {
  final String label;
  final ClientInvoiceStatsMonth month;

  const _ClientInvoiceChartPoint({
    required this.label,
    required this.month,
  });
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.selectedMonths,
    required this.isSpanish,
    required this.onSelected,
  });

  final int selectedMonths;
  final bool isSpanish;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Container(
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final months in const [6, 12, 24]) ...[
            if (months != 6)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.55),
              ),
            Tooltip(
              message: isSpanish ? '$months meses' : '$months months',
              child: Material(
                color: selectedMonths == months
                    ? cs.primaryContainer.withValues(alpha: 0.6)
                    : Colors.transparent,
                child: InkWell(
                  onTap: () => onSelected(months),
                  child: SizedBox(
                    width: 42,
                    child: Center(
                      child: Text(
                        '${months}m',
                        style: typo.bodySmall.copyWith(
                          color: selectedMonths == months
                              ? cs.primary
                              : cs.onSurfaceVariant,
                          fontWeight: selectedMonths == months
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryItem {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;
}

class _InvoiceSummaryStrip extends StatelessWidget {
  const _InvoiceSummaryStrip({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = <Widget>[];
          for (var index = 0; index < items.length; index++) {
            if (index > 0) {
              content.add(
                SizedBox(
                  height: 32,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
              );
            }
            final metric = _SummaryMetric(item: items[index]);
            content.add(
              constraints.maxWidth >= 720
                  ? Expanded(child: metric)
                  : SizedBox(width: index == 0 ? 160 : 124, child: metric),
            );
          }

          final row = Row(children: content);
          if (constraints.maxWidth >= 720) return row;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          );
        },
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typo.bodyMedium.copyWith(
              color: item.emphasized ? cs.primary : cs.onSurface,
              fontSize: 13.5,
              fontWeight: item.emphasized ? FontWeight.w900 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceStatsTooltip extends StatelessWidget {
  final ClientInvoiceStatsMonth month;
  final String monthLabel;

  const _InvoiceStatsTooltip({
    required this.month,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final currency = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: '€',
      decimalDigits: 2,
    );

    Widget line(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 108,
              child: Text(
                label,
                style: typo.bodySmall.copyWith(
                  color: cs.onInverseSurface.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              textAlign: TextAlign.right,
              style: typo.bodySmall.copyWith(
                color: cs.onInverseSurface,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.inverseSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: typo.bodyMedium.copyWith(
              color: cs.onInverseSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          line(
            isSpanish ? 'Total emitido' : 'Issued total',
            currency.format(month.issuedTotal),
          ),
          line(isSpanish ? 'Emitidas' : 'Issued count', '${month.issuedCount}'),
          line(
            isSpanish ? 'Total borrador' : 'Draft total',
            currency.format(month.draftTotal),
          ),
          line(isSpanish ? 'Borradores' : 'Draft count', '${month.draftCount}'),
          line(
            isSpanish ? 'Total anuladas' : 'Void total',
            currency.format(month.voidTotal),
          ),
          line(isSpanish ? 'Anuladas' : 'Void count', '${month.voidCount}'),
        ],
      ),
    );
  }
}

class _InvoiceStatsEmptyState extends StatelessWidget {
  const _InvoiceStatsEmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.insights_outlined,
          size: 44,
          color: cs.onSurfaceVariant.withValues(alpha: 0.55),
        ),
        const SizedBox(height: 12),
        Text(
          isSpanish
              ? 'Sin actividad de facturacion en este rango'
              : 'No invoice activity in this range',
          style: typo.bodyMedium.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isSpanish
              ? 'Los totales emitidos, borradores y anuladas son cero en los meses seleccionados.'
              : 'Issued, draft, and void totals are all zero for the selected months.',
          textAlign: TextAlign.center,
          style: typo.bodySmall.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
