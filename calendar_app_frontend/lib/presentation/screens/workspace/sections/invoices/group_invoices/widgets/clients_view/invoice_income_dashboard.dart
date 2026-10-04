import 'package:flutter/material.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'invoice_income_analytics.dart';

/// Monthly billing and dated collections. Balances describe today's payment
/// state of invoices issued in the selected period, not historical balances.
class InvoiceIncomeDashboard extends StatefulWidget {
  const InvoiceIncomeDashboard(
      {super.key,
      required this.invoices,
      required this.clients,
      required this.modeSelector,
      this.onRefresh});
  final List<Invoice> invoices;
  final List<GroupClient> clients;
  final Widget modeSelector;
  final Future<void> Function()? onRefresh;

  @override
  State<InvoiceIncomeDashboard> createState() => _InvoiceIncomeDashboardState();
}

class _InvoiceIncomeDashboardState extends State<InvoiceIncomeDashboard> {
  int _months = 12;
  DateTime _end = DateTime.now();
  bool _lines = false;
  bool _refreshing = false;
  bool _allClients = false;
  static const _blue = Color(0xFF3974C4);
  static const _green = Color(0xFF0AA66B);
  String t(String es, String en) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;
  String get locale => Localizations.localeOf(context).toLanguageTag();
  String money(num value) =>
      NumberFormat.currency(locale: locale, symbol: '€').format(value);

  int get monthCount {
    if (_months != 0) return _months;
    var first = DateTime(_end.year, _end.month);
    for (final invoice in widget.invoices) {
      for (final date in [invoice.issuedAtResolved, invoice.paidAt]) {
        if (date != null && date.toLocal().isBefore(first)) {
          first = date.toLocal();
        }
      }
    }
    return (_end.year - first.year) * 12 + _end.month - first.month + 1;
  }

  Future<void> _chooseEnd() async {
    final date = await showDatePicker(
        context: context,
        helpText: t('Último mes del periodo', 'Last month of period'),
        initialDate: _end,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        initialDatePickerMode: DatePickerMode.year);
    if (date != null && mounted) setState(() => _end = date);
  }

  Future<void> _refresh() async {
    if (_refreshing || widget.onRefresh == null) return;
    setState(() => _refreshing = true);
    try {
      await widget.onRefresh!();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(t('No se pudieron actualizar los ingresos.',
                'Could not refresh income.'))));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        padding: padding,
        decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: .4))),
        child: child);
  }

  Widget title(String value) => Text(value,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w800));
  Widget muted(String value) => Text(value,
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant));

  Widget metric(String label, String value, IconData icon, Color color,
          {String? note}) =>
      panel(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 25)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (note != null) ...[const SizedBox(height: 6), muted(note)],
        ])),
      ]));

  String trend(double value, double previous) {
    if (_months == 0 || previous == 0) {
      return t('Sin base de comparación', 'No comparison baseline');
    }
    final change = (value - previous) / previous.abs() * 100;
    return '${change >= 0 ? '+' : ''}${NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1).format(change)}% · ${t('vs. periodo anterior', 'vs. previous period')}';
  }

  @override
  Widget build(BuildContext context) {
    final count = monthCount;
    final data = buildInvoiceIncomeAnalytics(
        invoices: widget.invoices, months: count, now: _end);
    final previous = buildInvoiceIncomeAnalytics(
        invoices: widget.invoices,
        months: count,
        now: DateTime(_end.year, _end.month - count));
    final range =
        '${DateFormat.yMMM(locale).format(data.months.first.month)} – ${DateFormat.yMMM(locale).format(data.months.last.month)}';
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 1050;
      final columns = wide
          ? 4
          : constraints.maxWidth >= 550
              ? 2
              : 1;
      final cardWidth = (constraints.maxWidth - 12 * (columns - 1)) / columns;
      final cards = [
        metric(t('Facturado', 'Billed'), money(data.billedTotal),
            Icons.receipt_long_outlined, _blue,
            note: trend(data.billedTotal, previous.billedTotal)),
        metric(t('Cobrado', 'Collected'), money(data.collectedTotal),
            Icons.payments_outlined, _green,
            note: trend(data.collectedTotal, previous.collectedTotal)),
        metric(
            t('Pendiente de cobro', 'Outstanding'),
            money(data.outstandingTotal),
            Icons.schedule_outlined,
            Colors.orange,
            note: t('Saldo actual de las facturas del periodo',
                'Current balance of invoices in this period')),
        metric(
            t('Media mensual', 'Monthly average'),
            money(data.monthlyAverage),
            Icons.bar_chart_rounded,
            Colors.amber.shade800,
            note: trend(data.monthlyAverage, previous.monthlyAverage)),
      ];
      return SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 14,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _blue.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.insights_rounded,
                        color: _blue, size: 30)),
                const SizedBox(width: 16),
                Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(t('Análisis de ingresos', 'Income analysis'),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      muted(t(
                          'Evolución de las facturas emitidas y los pagos registrados.',
                          'Issued invoices and recorded payments over time.')),
                    ])),
              ]),
              Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                        onPressed: _chooseEnd,
                        icon: const Icon(Icons.date_range_outlined, size: 19),
                        label: Text(range)),
                    IconButton.outlined(
                        tooltip: t('Actualizar', 'Refresh'),
                        onPressed: widget.onRefresh == null || _refreshing
                            ? null
                            : _refresh,
                        icon: _refreshing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh)),
                  ]),
            ]),
        const SizedBox(height: 22),
        Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            spacing: 12,
            children: [
              widget.modeSelector,
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final n in [6, 12, 24, 0])
                  ChoiceChip(
                      label: Text(n == 0
                          ? t('Todo', 'All')
                          : '$n ${t('meses', 'months')}'),
                      selected: _months == n,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _months = n))
              ]),
            ]),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final card in cards) SizedBox(width: cardWidth, child: card)
        ]),
        const SizedBox(height: 14),
        _chart(data),
        const SizedBox(height: 14),
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _summary(data)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _ranking(data)),
          ])
        else ...[_summary(data), const SizedBox(height: 14), _ranking(data)],
      ]));
    });
  }

  Widget _chart(InvoiceIncomeAnalytics data) {
    String month(InvoiceIncomeMonth point, int _) =>
        DateFormat.yMMM(locale).format(point.month);
    return panel(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              title(t('Evolución de ingresos', 'Income over time')),
              const SizedBox(height: 4),
              muted(t('Facturado vs. cobrado por mes.',
                  'Billed vs. collected each month.'))
            ]),
            DropdownButton<bool>(
                value: _lines,
                underline: const SizedBox.shrink(),
                onChanged: (value) => setState(() => _lines = value!),
                items: [
                  DropdownMenuItem(
                      value: false,
                      child: Text(t('Gráfico de barras', 'Bar chart'))),
                  DropdownMenuItem(
                      value: true,
                      child: Text(t('Gráfico de líneas', 'Line chart'))),
                ]),
          ]),
      SizedBox(
          height: 300,
          child: !data.hasActivity
              ? Center(
                  child: Text(t('No hay actividad en este periodo.',
                      'No activity in this period.')))
              : SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  legend: const Legend(
                      isVisible: true,
                      position: LegendPosition.top,
                      alignment: ChartAlignment.far),
                  trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints),
                  tooltipBehavior: TooltipBehavior(enable: true, shared: true),
                  primaryXAxis: const CategoryAxis(
                      majorGridLines: MajorGridLines(width: 0),
                      labelIntersectAction:
                          AxisLabelIntersectAction.multipleRows),
                  primaryYAxis: NumericAxis(
                      numberFormat: NumberFormat.compactCurrency(
                          locale: locale, symbol: '€'),
                      axisLine: const AxisLine(width: 0),
                      majorTickLines: const MajorTickLines(size: 0),
                      majorGridLines: MajorGridLines(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: .25))),
                  series: <CartesianSeries<InvoiceIncomeMonth, String>>[
                    if (_lines)
                      LineSeries<InvoiceIncomeMonth, String>(
                          name: t('Facturado', 'Billed'),
                          color: _blue,
                          dataSource: data.months,
                          xValueMapper: month,
                          yValueMapper: (p, _) => p.billed,
                          animationDuration: 0)
                    else
                      ColumnSeries<InvoiceIncomeMonth, String>(
                          name: t('Facturado', 'Billed'),
                          color: _blue.withValues(alpha: .65),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(5)),
                          dataSource: data.months,
                          xValueMapper: month,
                          yValueMapper: (p, _) => p.billed,
                          animationDuration: 0),
                    LineSeries<InvoiceIncomeMonth, String>(
                        name: t('Cobrado', 'Collected'),
                        color: _green,
                        width: 2.5,
                        markerSettings: const MarkerSettings(
                            isVisible: true, width: 6, height: 6),
                        dataSource: data.months,
                        xValueMapper: month,
                        yValueMapper: (p, _) => p.collected,
                        animationDuration: 0),
                  ],
                )),
      muted(t('Cobros según la fecha de pago registrada en cada factura.',
          'Collections use the payment date recorded on each invoice.')),
    ]));
  }

  Widget _summary(InvoiceIncomeAnalytics data) {
    final entries = [
      (
        Icons.receipt_long_outlined,
        t('Facturas emitidas', 'Issued invoices'),
        '${data.invoiceCount}'
      ),
      (
        Icons.people_outline,
        t('Clientes con actividad', 'Active clients'),
        '${data.clientTotals.length}'
      ),
      (
        Icons.schedule,
        t('Plazo medio de cobro', 'Average payment time'),
        data.averagePaymentDays == null
            ? '—'
            : '${data.averagePaymentDays!.round()} ${t('días', 'days')}'
      ),
      (
        Icons.percent,
        t('Ratio de cobro', 'Collection ratio'),
        data.collectionRatio == null
            ? '—'
            : NumberFormat.decimalPercentPattern(
                    locale: locale, decimalDigits: 1)
                .format(data.collectionRatio)
      ),
    ];
    return panel(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      title(t('Resumen del periodo', 'Period summary')),
      const SizedBox(height: 20),
      LayoutBuilder(
          builder: (context, constraints) =>
              Wrap(spacing: 14, runSpacing: 18, children: [
                for (final entry in entries)
                  SizedBox(
                      width: (constraints.maxWidth -
                              (constraints.maxWidth >= 650 ? 42 : 14)) /
                          (constraints.maxWidth >= 650 ? 4 : 2),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(entry.$1, color: _blue, size: 22),
                            const SizedBox(height: 8),
                            muted(entry.$2),
                            const SizedBox(height: 6),
                            title(entry.$3),
                          ])),
              ])),
      const SizedBox(height: 16),
      muted(t(
          'Plazo: facturas saldadas con fecha de pago. Ratio: importe cobrado de las facturas emitidas en el periodo.',
          'Payment time: settled invoices with a payment date. Ratio: paid share of invoices issued in the period.')),
    ]));
  }

  Widget _ranking(InvoiceIncomeAnalytics data) {
    final ranked = data.clientTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final names = {for (final client in widget.clients) client.id: client.name};
    for (final invoice in widget.invoices) {
      names.putIfAbsent(
          invoice.clientId,
          () =>
              invoice.clientName ??
              invoice.billingName ??
              t('Cliente no disponible', 'Unavailable client'));
    }
    final visible = _allClients ? ranked : ranked.take(3).toList();
    return panel(
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child:
                title(t('Top clientes por ingresos', 'Top clients by income'))),
        if (ranked.length > 3)
          TextButton(
              onPressed: () => setState(() => _allClients = !_allClients),
              child: Text(_allClients
                  ? t('Ver menos', 'Show less')
                  : t('Ver todos', 'View all')))
      ]),
      const SizedBox(height: 12),
      if (ranked.isEmpty)
        muted(
            t('Sin facturas en este periodo.', 'No invoices in this period.')),
      for (var i = 0; i < visible.length; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(children: [
              CircleAvatar(
                  radius: 14,
                  backgroundColor: _blue.withValues(alpha: .12),
                  child: Text('${i + 1}',
                      style: const TextStyle(fontSize: 12, color: _blue))),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Row(children: [
                      Expanded(
                          child: Text(names[visible[i].key] ?? '—',
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(money(visible[i].value),
                          style: const TextStyle(fontWeight: FontWeight.w600))
                    ]),
                    const SizedBox(height: 7),
                    LinearProgressIndicator(
                        value: ranked.first.value > 0
                            ? (visible[i].value / ranked.first.value)
                                .clamp(0, 1)
                            : 0,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(8),
                        color: _blue.withValues(alpha: .5),
                        backgroundColor: _blue.withValues(alpha: .06)),
                  ])),
            ])),
    ]));
  }
}
