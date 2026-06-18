import 'package:flutter/material.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/group_model/client/client_invoice_stats.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/services_clients/widgets/common_views.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
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
        return _InvoiceStatsTooltip(month: chartPoint.month);
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
      symbol: 'EUR ',
      decimalDigits: 2,
    );
    final compactCurrency = NumberFormat.compactCurrency(
      locale: locale,
      symbol: 'EUR ',
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSpanish ? 'Grafico de facturacion' : 'Invoice graph',
                      style: typo.titleLarge.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isSpanish
                          ? 'Tendencia mensual de las facturas del cliente. La barra principal refleja el total emitido y el tooltip incluye borradores y anuladas.'
                          : 'Monthly invoice trend for this client. The main bars show issued totals and the tooltip includes draft and void values.',
                      style: typo.bodySmall.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _loadStats,
                tooltip: isSpanish ? 'Actualizar' : 'Refresh',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [6, 12, 24]
                .map(
                  (months) => _RangeChip(
                    months: months,
                    label: isSpanish ? '$months m' : '${months}m',
                    selected: _selectedMonths == months,
                    onTap: () => _changeRange(months),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                label: isSpanish ? 'Total emitido' : 'Issued total',
                value: currency.format(stats.summary.issuedTotal),
                icon: Icons.payments_outlined,
                background: cs.primaryContainer.withValues(alpha: 0.45),
                foreground: cs.onPrimaryContainer,
              ),
              _SummaryChip(
                label: isSpanish ? 'Emitidas' : 'Issued count',
                value: '${stats.summary.issuedCount}',
                icon: Icons.receipt_long_outlined,
                background: cs.secondaryContainer.withValues(alpha: 0.45),
                foreground: cs.onSecondaryContainer,
              ),
              _SummaryChip(
                label: isSpanish ? 'Borradores' : 'Draft count',
                value: '${stats.summary.draftCount}',
                icon: Icons.edit_note_outlined,
                background: cs.tertiaryContainer.withValues(alpha: 0.45),
                foreground: cs.onTertiaryContainer,
              ),
              _SummaryChip(
                label: isSpanish ? 'Anuladas' : 'Void count',
                value: '${stats.summary.voidCount}',
                icon: Icons.cancel_outlined,
                background: cs.errorContainer.withValues(alpha: 0.55),
                foreground: cs.onErrorContainer,
              ),
              _SummaryChip(
                label: isSpanish ? 'Ultima emitida' : 'Last issued',
                value: stats.summary.lastIssuedAt == null
                    ? (isSpanish ? 'Sin factura emitida' : 'No issued invoice')
                    : materialLocalizations
                        .formatShortDate(stats.summary.lastIssuedAt!.toLocal()),
                icon: Icons.schedule_outlined,
                background: cs.surfaceContainerHighest.withValues(alpha: 0.8),
                foreground: cs.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSpanish
                      ? 'Totales emitidos por mes'
                      : 'Issued totals by month',
                  style: typo.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isSpanish ? 'Rango' : 'Range'}: ${materialLocalizations.formatShortDate(stats.range.from?.toLocal() ?? DateTime.now())} - ${materialLocalizations.formatShortDate(stats.range.to?.toLocal() ?? DateTime.now())}',
                  style: typo.bodySmall.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (!stats.hasAnyMonthlyActivity)
                  const SizedBox(
                    height: 260,
                    child: Center(
                      child: _InvoiceStatsEmptyState(),
                    ),
                  )
                else
                  SizedBox(
                    height: 280,
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      tooltipBehavior: _tooltipBehavior,
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelRotation: points.length > 8 ? -45 : 0,
                        axisLine: AxisLine(
                          color: cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                        labelStyle: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      primaryYAxis: NumericAxis(
                        majorTickLines: const MajorTickLines(size: 0),
                        axisLine: const AxisLine(width: 0),
                        numberFormat: compactCurrency,
                        labelStyle: typo.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        majorGridLines: MajorGridLines(
                          width: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.15),
                        ),
                      ),
                      series: <CartesianSeries<_ClientInvoiceChartPoint,
                          String>>[
                        ColumnSeries<_ClientInvoiceChartPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) => point.label,
                          yValueMapper: (point, _) => point.month.issuedTotal,
                          color: cs.primary,
                          width: 0.58,
                          borderRadius: BorderRadius.circular(8),
                          enableTooltip: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
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

    return DateFormat.yMMM(locale).format(DateTime(year, month));
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

class _RangeChip extends StatelessWidget {
  final int months;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.months,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    if (months <= 6) return Icons.calendar_view_month_outlined;
    if (months <= 12) return Icons.event_available_outlined;
    return Icons.history_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final bg = selected ? cs.primary : Colors.transparent;
    final fg = selected ? cs.onPrimary : cs.onSurface;

    return Tooltip(
      message: Localizations.localeOf(context).languageCode == 'es'
          ? '$months meses'
          : '$months months',
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? cs.primary : cs.outlineVariant,
            width: 1.2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check_rounded : _icon,
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: typo.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final typo = AppTypography.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: foreground),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodySmall.copyWith(
                    color: foreground.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.bodyMedium.copyWith(
                    color: foreground,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceStatsTooltip extends StatelessWidget {
  final ClientInvoiceStatsMonth month;

  const _InvoiceStatsTooltip({
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final typo = AppTypography.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final currency = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: 'EUR ',
      decimalDigits: 2,
    );

    Widget line(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: typo.bodySmall.copyWith(
                color: cs.onInverseSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              style: typo.bodySmall.copyWith(
                color: cs.onInverseSurface,
                fontWeight: FontWeight.w800,
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
            month.month,
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
