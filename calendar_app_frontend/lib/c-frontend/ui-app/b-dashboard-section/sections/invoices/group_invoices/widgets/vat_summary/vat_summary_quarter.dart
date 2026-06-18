import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'vat_summary_utils.dart';

class VatQuarterSummary extends StatelessWidget {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? data;
  final List<Map<String, dynamic>>? expenseEntries;
  final Map<String, dynamic>? invoiceSummary;
  final Map<String, dynamic>? expenseSummary;
  final VoidCallback onRetry;

  const VatQuarterSummary({
    super.key,
    required this.loading,
    required this.error,
    required this.data,
    this.expenseEntries,
    this.invoiceSummary,
    this.expenseSummary,
    required this.onRetry,
  });

  Map<String, dynamic>? _totals() {
    final raw = data?['totals'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  List<Map<String, dynamic>> _entries(String key) {
    final raw = data?[key];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  List<Map<String, dynamic>> _entriesFromDynamic(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  double _entryBaseValue(Map<String, dynamic> entry) {
    return parseVatNum(
          entry['baseTotal'] ?? entry['subtotal'] ?? entry['base'],
        ) ??
        0;
  }

  double _entryTaxValue(Map<String, dynamic> entry) {
    return parseVatNum(
          entry['vatTotal'] ?? entry['tax'] ?? entry['vat'],
        ) ??
        0;
  }

  bool _hasDisplayableVat(Map<String, dynamic> entry) {
    return _entryTaxValue(entry) > 0.005;
  }

  List<Map<String, dynamic>> _entriesWithVat(
    List<Map<String, dynamic>> entries,
  ) {
    return entries.where(_hasDisplayableVat).toList(growable: false);
  }

  int? _readCount(List<dynamic> candidates) {
    for (final candidate in candidates) {
      if (candidate is num) {
        final value = candidate.toInt();
        if (value > 0) return value;
      }
      final parsed = int.tryParse(candidate?.toString().trim() ?? '');
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  List<Map<String, dynamic>> _normalizedExpenseEntries() {
    final rawEntries = expenseEntries ?? const <Map<String, dynamic>>[];
    return rawEntries.map((entry) {
      String pickText(List<String> keys) {
        for (final key in keys) {
          final raw = entry[key];
          if (raw == null) continue;
          final text = raw.toString().trim();
          if (text.isNotEmpty) return text;
        }
        return '';
      }

      final provider = entry['provider'];
      final providerName =
          provider is Map ? (provider['name']?.toString().trim() ?? '') : '';
      final providerId = provider is Map
          ? ((provider['id'] ?? provider['_id'] ?? provider['providerId'])
                  ?.toString()
                  .trim() ??
              '')
          : '';

      return <String, dynamic>{
        ...entry,
        'id': pickText(['id', '_id', 'expenseId']),
        'providerName': providerName.isNotEmpty
            ? providerName
            : pickText(['providerName', 'vendorName', 'vendor']),
        'providerId':
            providerId.isNotEmpty ? providerId : pickText(['providerId']),
        'invoiceNumber': pickText(['invoiceNumber', 'invoice', 'number']),
        'issueDate': pickText(['issueDate', 'date', 'issuedAt']),
        'baseTotal': entry['subtotal'] ?? entry['baseTotal'] ?? entry['base'],
        'vatTotal': entry['taxTotal'] ?? entry['vatTotal'] ?? entry['tax'],
        'grandTotal': entry['total'] ?? entry['grandTotal'] ?? entry['amount'],
      };
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, style: t.bodySmall),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(l.tryAgain),
            ),
          ],
        ),
      );
    }
    if (data == null || data!.isEmpty) {
      return Center(
        child: Text(l.vatSummaryNoData, style: t.bodySmall),
      );
    }

    final totals = _totals();
    final sales = data?['sales'];
    final salesMap = sales is Map
        ? Map<String, dynamic>.from(sales)
        : const <String, dynamic>{};
    final purchases = data?['purchases'];
    final purchasesMap = purchases is Map
        ? Map<String, dynamic>.from(purchases)
        : const <String, dynamic>{};
    final normalizedExpenseEntries =
        _entriesWithVat(_normalizedExpenseEntries());
    final ingresosByInvoice = _entries('ingresos_by_invoice');
    final ingresos = salesMap['byInvoice'] is List
        ? (salesMap['byInvoice'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : (ingresosByInvoice.isNotEmpty
            ? ingresosByInvoice
            : _entries('ingresos_by_client'));
    final purchasesByProvider = _entriesFromDynamic(
      purchasesMap['byProvider'] ??
          purchasesMap['providers'] ??
          purchasesMap['byVendor'],
    );
    final gastosRaw = normalizedExpenseEntries.isNotEmpty
        ? normalizedExpenseEntries
        : purchasesByProvider.isNotEmpty
            ? purchasesByProvider
            : (_entries('gastos_by_provider').isNotEmpty
                ? _entries('gastos_by_provider')
                : (_entries('expenses_by_provider').isNotEmpty
                    ? _entries('expenses_by_provider')
                    : _entries('purchases_by_provider')));
    final gastos = _entriesWithVat(gastosRaw);
    final showingExpenseEntries = normalizedExpenseEntries.isNotEmpty;
    final ingresosBase = invoiceSummary?['subtotal'] ??
        salesMap['totalBase'] ??
        totals?['ingresosBase'] ??
        totals?['ingresosBaseTotal'];
    final ingresosTax = invoiceSummary?['taxTotal'] ??
        salesMap['totalTax'] ??
        totals?['ingresosVat'] ??
        totals?['ingresosTax'];
    final ingresosCount = _readCount([
      invoiceSummary?['count'],
      salesMap['count'],
      salesMap['invoiceCount'],
      salesMap['totalInvoices'],
      salesMap['documentsCount'],
      totals?['ingresosCount'],
      totals?['salesCount'],
      data?['salesCount'],
      data?['invoiceCount'],
    ]);
    final filteredGastosBase = (expenseSummary?['subtotal'] is num ||
            expenseSummary?['subtotal'] != null)
        ? (parseVatNum(expenseSummary?['subtotal']) ?? 0)
        : gastos.fold<double>(
            0,
            (sum, entry) => sum + _entryBaseValue(entry),
          );
    final filteredGastosTax = (expenseSummary?['taxTotal'] is num ||
            expenseSummary?['taxTotal'] != null)
        ? (parseVatNum(expenseSummary?['taxTotal']) ?? 0)
        : gastos.fold<double>(
            0,
            (sum, entry) => sum + _entryTaxValue(entry),
          );
    final gastosCount = _readCount([
      expenseSummary?['count'],
      purchasesMap['count'],
      totals?['gastosCount'],
      data?['expenseCount'],
    ]);
    final ivaValue = (parseVatNum(ingresosTax) ?? 0) - filteredGastosTax;
    final isPositive = ivaValue >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final salesBaseValue = parseVatNum(ingresosBase) ?? 0;
        final salesTaxValue = parseVatNum(ingresosTax) ?? 0;
        final purchaseBaseValue =
            (gastos.isEmpty ? 0 : filteredGastosBase).toDouble();
        final purchaseTaxValue =
            (gastos.isEmpty ? 0 : filteredGastosTax).toDouble();
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          children: [
            _VatComparisonChartCard(
              salesBase: salesBaseValue,
              salesTax: salesTaxValue,
              purchaseBase: purchaseBaseValue,
              purchaseTax: purchaseTaxValue,
              netVat: ivaValue,
              isPositive: isPositive,
            ),
            const SizedBox(height: 10),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VatSectionCard(
                      title: l.vatSummarySalesTitle,
                      entries: ingresos,
                      totalCount: ingresosCount,
                      nameKey: 'invoiceNumber',
                      idKey: 'invoiceId',
                      secondaryNameKey: 'clientName',
                      sortByInvoiceNumber: true,
                      totalBase: ingresosBase,
                      totalTax: ingresosTax,
                      accentColor: cs.primary,
                      icon: Icons.trending_up,
                      previewCount: 6,
                      previewLabel: 'Top facturas',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VatSectionCard(
                      title: l.vatSummaryPurchasesTitle,
                      entries: gastos,
                      totalCount: gastosCount,
                      nameKey: 'providerName',
                      idKey: showingExpenseEntries ? 'id' : 'providerId',
                      countKey: showingExpenseEntries ? null : 'count',
                      invoiceNumberKeys: showingExpenseEntries
                          ? const ['invoiceNumber', 'invoice', 'number']
                          : const [],
                      totalBase: gastos.isEmpty ? 0 : filteredGastosBase,
                      totalTax: gastos.isEmpty ? 0 : filteredGastosTax,
                      accentColor: cs.tertiary,
                      icon: Icons.shopping_bag_outlined,
                      hideZeroTaxEntries: true,
                      previewCount: 6,
                      previewLabel: 'Top gastos',
                    ),
                  ),
                ],
              )
            else ...[
              VatSectionCard(
                title: l.vatSummarySalesTitle,
                entries: ingresos,
                totalCount: ingresosCount,
                nameKey: 'invoiceNumber',
                idKey: 'invoiceId',
                secondaryNameKey: 'clientName',
                sortByInvoiceNumber: true,
                totalBase: ingresosBase,
                totalTax: ingresosTax,
                accentColor: cs.primary,
                icon: Icons.trending_up,
                previewCount: 6,
                previewLabel: 'Top facturas',
              ),
              const SizedBox(height: 10),
              VatSectionCard(
                title: l.vatSummaryPurchasesTitle,
                entries: gastos,
                totalCount: gastosCount,
                nameKey: 'providerName',
                idKey: showingExpenseEntries ? 'id' : 'providerId',
                countKey: showingExpenseEntries ? null : 'count',
                invoiceNumberKeys: showingExpenseEntries
                    ? const ['invoiceNumber', 'invoice', 'number']
                    : const [],
                totalBase: gastos.isEmpty ? 0 : filteredGastosBase,
                totalTax: gastos.isEmpty ? 0 : filteredGastosTax,
                accentColor: cs.tertiary,
                icon: Icons.shopping_bag_outlined,
                hideZeroTaxEntries: true,
                previewCount: 6,
                previewLabel: 'Top gastos',
              ),
            ],
            const SizedBox(height: 10),
            _NetIvaCard(ivaValue: ivaValue, isPositive: isPositive),
          ],
        );
      },
    );
  }
}

class _NetIvaCard extends StatelessWidget {
  final double ivaValue;
  final bool isPositive;

  const _NetIvaCard({required this.ivaValue, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final color = isPositive ? cs.primary : cs.error;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(
                isPositive ? Icons.south_west : Icons.north_east,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.vatSummaryNetTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    isPositive ? 'A pagar a Hacienda' : 'A devolver',
                    style: t.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                formatVatAmount(ivaValue),
                style: t.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VatSectionCard extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> entries;
  final int? totalCount;
  final String nameKey;
  final String? idKey;
  final String? secondaryNameKey;
  final String? countKey;
  final List<String> invoiceNumberKeys;
  final bool hideZeroTaxEntries;
  final bool sortByInvoiceNumber;
  final dynamic totalBase;
  final dynamic totalTax;
  final Color accentColor;
  final IconData icon;
  final int previewCount;
  final String? previewLabel;

  const VatSectionCard({
    super.key,
    required this.title,
    required this.entries,
    this.totalCount,
    required this.nameKey,
    this.idKey,
    this.secondaryNameKey,
    this.countKey,
    this.invoiceNumberKeys = const [],
    this.hideZeroTaxEntries = false,
    this.sortByInvoiceNumber = false,
    required this.totalBase,
    required this.totalTax,
    required this.accentColor,
    required this.icon,
    this.previewCount = 6,
    this.previewLabel,
  });

  @override
  State<VatSectionCard> createState() => _VatSectionCardState();
}

class _VatComparisonChartCard extends StatelessWidget {
  final double salesBase;
  final double salesTax;
  final double purchaseBase;
  final double purchaseTax;
  final double netVat;
  final bool isPositive;

  const _VatComparisonChartCard({
    required this.salesBase,
    required this.salesTax,
    required this.purchaseBase,
    required this.purchaseTax,
    required this.netVat,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final chartData = [
      _VatChartDatum(
        label: 'Base',
        sales: salesBase,
        purchases: purchaseBase,
      ),
      _VatChartDatum(
        label: 'IVA',
        sales: salesTax,
        purchases: purchaseTax,
      ),
      _VatChartDatum(
        label: 'Total',
        sales: salesBase + salesTax,
        purchases: purchaseBase + purchaseTax,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comparativa del trimestre',
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vista compacta para detectar diferencias antes de abrir el detalle.',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _VatMetricChip(
                    label: 'Ventas IVA',
                    value: formatVatAmount(salesTax),
                    color: cs.primary,
                  ),
                  _VatMetricChip(
                    label: 'Compras IVA',
                    value: formatVatAmount(purchaseTax),
                    color: cs.tertiary,
                  ),
                  _VatMetricChip(
                    label: isPositive ? 'Neto a pagar' : 'Neto a devolver',
                    value: formatVatAmount(netVat),
                    color: isPositive ? cs.primary : cs.error,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 240,
            child: SfCartesianChart(
              margin: EdgeInsets.zero,
              plotAreaBorderWidth: 0,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.compactCurrency(
                  locale: 'es_ES',
                  symbol: '',
                  decimalDigits: 0,
                ),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(size: 0),
                labelStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
                majorGridLines: MajorGridLines(
                  width: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.2),
                ),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <CartesianSeries<_VatChartDatum, String>>[
                ColumnSeries<_VatChartDatum, String>(
                  name: 'Ventas',
                  dataSource: chartData,
                  xValueMapper: (datum, _) => datum.label,
                  yValueMapper: (datum, _) => datum.sales,
                  color: cs.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  width: 0.34,
                ),
                ColumnSeries<_VatChartDatum, String>(
                  name: 'Compras',
                  dataSource: chartData,
                  xValueMapper: (datum, _) => datum.label,
                  yValueMapper: (datum, _) => datum.purchases,
                  color: cs.tertiary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  width: 0.34,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VatChartDatum {
  final String label;
  final double sales;
  final double purchases;

  const _VatChartDatum({
    required this.label,
    required this.sales,
    required this.purchases,
  });
}

class _VatMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _VatMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _VatSectionCardState extends State<VatSectionCard> {
  // null = no sort, true = asc, false = desc — default asc (by invoice number)
  bool? _sortAsc = true;
  bool _showAll = false;
  final Set<String> _expandedIds = {};
  final RegExp _digitRun = RegExp(r'\d+');

  void _toggleSortDir(bool ascending) {
    setState(() {
      _sortAsc = _sortAsc == ascending ? null : ascending;
    });
  }

  String _entryKey(int index, Map<String, dynamic> entry) {
    for (final key in ['id', '_id', 'invoiceId', 'providerId']) {
      final val = entry[key]?.toString().trim();
      if (val != null && val.isNotEmpty) return val;
    }
    return 'entry_$index';
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  bool _hasDisplayableTax(Map<String, dynamic> entry) {
    final taxValue = parseVatNum(
          entry['vatTotal'] ?? entry['tax'] ?? entry['vat'],
        ) ??
        0;
    return taxValue.abs() >= 0.005;
  }

  List<Map<String, dynamic>> get _sortedEntries {
    final baseEntries = widget.hideZeroTaxEntries
        ? widget.entries.where(_hasDisplayableTax).toList(growable: false)
        : widget.entries;
    if (_sortAsc == null) return baseEntries;
    final sorted = List<Map<String, dynamic>>.from(baseEntries);
    sorted.sort((a, b) {
      final aVal = (a[widget.nameKey]?.toString() ?? '').trim();
      final bVal = (b[widget.nameKey]?.toString() ?? '').trim();
      final comparison = widget.sortByInvoiceNumber
          ? _compareInvoiceNumbers(aVal, bVal)
          : aVal.compareTo(bVal);
      return _sortAsc! ? comparison : -comparison;
    });
    return sorted;
  }

  List<Map<String, dynamic>> get _displayEntries {
    final sorted = _sortedEntries;
    if (_showAll || sorted.length <= widget.previewCount) {
      return sorted;
    }
    final byTax = List<Map<String, dynamic>>.from(sorted)
      ..sort((a, b) => _entryTaxValue(b).compareTo(_entryTaxValue(a)));
    return byTax.take(widget.previewCount).toList(growable: false);
  }

  double _entryTaxValue(Map<String, dynamic> entry) {
    return parseVatNum(entry['vatTotal'] ?? entry['tax'] ?? entry['vat']) ?? 0;
  }

  int _compareInvoiceNumbers(String a, String b) {
    final aDigits = _digitRun
        .allMatches(a)
        .map((match) => int.tryParse(match.group(0)!) ?? 0)
        .toList(growable: false);
    final bDigits = _digitRun
        .allMatches(b)
        .map((match) => int.tryParse(match.group(0)!) ?? 0)
        .toList(growable: false);

    final limit =
        aDigits.length > bDigits.length ? aDigits.length : bDigits.length;
    for (var i = 0; i < limit; i++) {
      final aPart = i < aDigits.length ? aDigits[i] : -1;
      final bPart = i < bDigits.length ? bDigits[i] : -1;
      if (aPart != bPart) return aPart.compareTo(bPart);
    }

    return a.compareTo(b);
  }

  List<String> _extractInvoiceNumbers(Map<String, dynamic> entry) {
    final collected = <String>{};

    for (final key in widget.invoiceNumberKeys) {
      final raw = entry[key];
      if (raw is String && raw.trim().isNotEmpty) {
        collected.add(raw.trim());
      } else if (raw is num) {
        collected.add(raw.toString());
      } else if (raw is List) {
        for (final item in raw) {
          if (item == null) continue;
          final text = item.toString().trim();
          if (text.isNotEmpty) collected.add(text);
        }
      }
    }

    final invoicesRaw = entry['invoices'];
    if (invoicesRaw is List) {
      for (final item in invoicesRaw) {
        if (item is! Map) continue;
        final inv = Map<String, dynamic>.from(item);
        for (final key in const ['invoiceNumber', 'invoiceNo', 'number']) {
          final raw = inv[key];
          if (raw == null) continue;
          final text = raw.toString().trim();
          if (text.isNotEmpty) collected.add(text);
        }
      }
    }

    return collected.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasTotals = (parseVatNum(widget.totalBase) ?? 0) != 0 ||
        (parseVatNum(widget.totalTax) ?? 0) != 0;
    final sortedEntries = _sortedEntries;
    final displayEntries = _displayEntries;
    final badgeCount = widget.totalCount == null || widget.totalCount! <= 0
        ? sortedEntries.length
        : widget.totalCount!;
    final hasHiddenEntries = sortedEntries.length > displayEntries.length;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(widget.icon, size: 17, color: widget.accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.title,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (sortedEntries.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: widget.accentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: t.bodySmall.copyWith(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                _VatSummarySortButton(
                  icon: Icons.arrow_upward,
                  isActive: _sortAsc == true,
                  accentColor: widget.accentColor,
                  borderColor: cs.outlineVariant,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => _toggleSortDir(true),
                ),
                const SizedBox(width: 5),
                _VatSummarySortButton(
                  icon: Icons.arrow_downward,
                  isActive: _sortAsc == false,
                  accentColor: widget.accentColor,
                  borderColor: cs.outlineVariant,
                  inactiveColor: cs.onSurfaceVariant,
                  onTap: () => _toggleSortDir(false),
                ),
              ],
            ),
            if (!_showAll &&
                widget.previewLabel != null &&
                sortedEntries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.previewLabel!,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (sortedEntries.isEmpty && !hasTotals)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l.vatSummaryNoRates,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Column(
                children: displayEntries.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;
                  final entryKey = _entryKey(index, entry);
                  final isExpanded = _expandedIds.contains(entryKey);

                  final name = entry[widget.nameKey]?.toString().trim() ?? '';
                  final fallbackId = widget.idKey == null
                      ? ''
                      : (entry[widget.idKey]?.toString().trim() ?? '');
                  final displayName = name.isNotEmpty
                      ? name
                      : (fallbackId.isNotEmpty ? 'ID: $fallbackId' : '-');
                  final secondaryName = widget.secondaryNameKey == null
                      ? ''
                      : (entry[widget.secondaryNameKey]?.toString().trim() ??
                          '');
                  final invoiceNumbers = widget.invoiceNumberKeys.isEmpty
                      ? const <String>[]
                      : _extractInvoiceNumbers(entry);
                  final issueDateRaw =
                      entry['issueDate'] ?? entry['date'] ?? entry['issuedAt'];
                  final issueDate = issueDateRaw is DateTime
                      ? issueDateRaw
                      : (issueDateRaw is String
                          ? DateTime.tryParse(issueDateRaw)
                          : null);
                  final issueDateLabel = issueDate == null
                      ? ''
                      : '${issueDate.year.toString().padLeft(4, '0')}-'
                          '${issueDate.month.toString().padLeft(2, '0')}-'
                          '${issueDate.day.toString().padLeft(2, '0')}';
                  final count = widget.countKey == null
                      ? ''
                      : (entry[widget.countKey]?.toString().trim() ?? '');
                  final base = formatVatAmount(
                      entry['baseTotal'] ?? entry['subtotal'] ?? entry['base']);
                  final tax = formatVatAmount(
                      entry['vatTotal'] ?? entry['tax'] ?? entry['vat']);
                  final total = formatVatAmount(
                      entry['grandTotal'] ?? entry['total'] ?? entry['amount']);

                  // Compute VAT rate for the expanded preview
                  final baseNum = parseVatNum(
                        entry['baseTotal'] ??
                            entry['subtotal'] ??
                            entry['base'],
                      ) ??
                      0;
                  final taxNum = parseVatNum(
                        entry['vatTotal'] ?? entry['tax'] ?? entry['vat'],
                      ) ??
                      0;
                  final vatRate =
                      baseNum > 0 ? ((taxNum / baseNum) * 100).round() : null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? widget.accentColor.withValues(alpha: 0.04)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isExpanded
                            ? widget.accentColor.withValues(alpha: 0.3)
                            : cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: InkWell(
                      onTap: () => _toggleExpanded(entryKey),
                      borderRadius: BorderRadius.circular(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Collapsed row
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayName,
                                        style: t.bodySmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (secondaryName.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          secondaryName,
                                          style: t.bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      if (issueDateLabel.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          issueDateLabel,
                                          style: t.bodySmall.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // In collapsed state show just the IVA chip
                                VatAmountChip(
                                  label: l.vatSummaryTaxLabel,
                                  value: tax,
                                  color: Colors.transparent,
                                  textColor: widget.accentColor,
                                  borderColor:
                                      widget.accentColor.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 6),
                                AnimatedRotation(
                                  turns: isExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expanded preview panel
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            child: isExpanded
                                ? _EntryPreviewPanel(
                                    l: l,
                                    t: t,
                                    cs: cs,
                                    accentColor: widget.accentColor,
                                    base: base,
                                    tax: tax,
                                    total: total,
                                    vatRate: vatRate,
                                    count: count,
                                    invoiceNumbers: invoiceNumbers,
                                    issueDateLabel: issueDateLabel,
                                    secondaryName: secondaryName,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            if (hasHiddenEntries || _showAll) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  icon: Icon(
                    _showAll
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    size: 16,
                  ),
                  label: Text(
                    _showAll
                        ? 'Mostrar resumen'
                        : 'Ver todo (${sortedEntries.length})',
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    foregroundColor: widget.accentColor,
                    textStyle: t.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Divider(color: cs.outlineVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.vatSummaryTotalsLabel,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    VatAmountChip(
                      label: l.vatSummaryBaseLabel,
                      value: formatVatAmount(widget.totalBase),
                      color: Colors.transparent,
                      textColor: widget.accentColor,
                      borderColor: widget.accentColor.withValues(alpha: 0.5),
                    ),
                    VatAmountChip(
                      label: l.vatSummaryTaxLabel,
                      value: formatVatAmount(widget.totalTax),
                      color: Colors.transparent,
                      textColor: cs.onSurface,
                      borderColor: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    VatAmountChip(
                      label: l.expenseUploadLinesTotalLabel,
                      value: formatVatAmount(
                          (parseVatNum(widget.totalBase) ?? 0) +
                              (parseVatNum(widget.totalTax) ?? 0)),
                      color: Colors.transparent,
                      textColor: cs.onSurface,
                      borderColor: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryPreviewPanel extends StatelessWidget {
  final AppLocalizations l;
  final AppTypography t;
  final ColorScheme cs;
  final Color accentColor;
  final String base;
  final String tax;
  final String total;
  final int? vatRate;
  final String count;
  final List<String> invoiceNumbers;
  final String issueDateLabel;
  final String secondaryName;

  const _EntryPreviewPanel({
    required this.l,
    required this.t,
    required this.cs,
    required this.accentColor,
    required this.base,
    required this.tax,
    required this.total,
    required this.vatRate,
    required this.count,
    required this.invoiceNumbers,
    required this.issueDateLabel,
    required this.secondaryName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount breakdown row
          Row(
            children: [
              Expanded(
                child: _PreviewAmountBlock(
                  label: l.vatSummaryBaseLabel,
                  value: base,
                  color: accentColor,
                  t: t,
                  cs: cs,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreviewAmountBlock(
                  label: l.vatSummaryTaxLabel,
                  value: tax,
                  color: accentColor,
                  t: t,
                  cs: cs,
                  badge: vatRate != null ? '$vatRate%' : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PreviewAmountBlock(
                  label: l.expenseUploadLinesTotalLabel,
                  value: total,
                  color: cs.onSurface,
                  t: t,
                  cs: cs,
                  isMuted: true,
                ),
              ),
            ],
          ),
          // Extra metadata
          if (count.isNotEmpty || invoiceNumbers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (count.isNotEmpty)
                  _MetaChip(
                    icon: Icons.receipt_long_outlined,
                    label: '$count docs',
                    cs: cs,
                    t: t,
                  ),
                ...invoiceNumbers.map(
                  (invoiceNum) => _MetaChip(
                    icon: Icons.tag,
                    label: invoiceNum,
                    cs: cs,
                    t: t,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewAmountBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final AppTypography t;
  final ColorScheme cs;
  final String? badge;
  final bool isMuted;

  const _PreviewAmountBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.t,
    required this.cs,
    this.badge,
    this.isMuted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isMuted
            ? cs.surfaceContainerHighest.withValues(alpha: 0.4)
            : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMuted
              ? cs.outlineVariant.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: t.bodySmall.copyWith(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: t.bodySmall.copyWith(
              color: isMuted ? cs.onSurface : color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;
  final AppTypography t;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.cs,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VatSummarySortButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color accentColor;
  final Color borderColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _VatSummarySortButton({
    required this.icon,
    required this.isActive,
    required this.accentColor,
    required this.borderColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: 0.5)
                : borderColor.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          size: 13,
          color: isActive ? accentColor : inactiveColor,
        ),
      ),
    );
  }
}

class VatAmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color? borderColor;

  const VatAmountChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Text(
        '$label $value',
        style: t.bodySmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
