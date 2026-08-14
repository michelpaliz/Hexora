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

  Map<String, dynamic> _previousPeriodData() {
    for (final candidate in [
      data?['previousQuarter'],
      data?['previousPeriod'],
      data?['previous'],
      data?['comparison'] is Map
          ? (data!['comparison'] as Map)['previous']
          : null,
    ]) {
      if (candidate is Map) return Map<String, dynamic>.from(candidate);
    }
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _insights() {
    final raw = data?['insights'];
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => (item['message'] ?? '').toString().trim().isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> _comparisonData() {
    final raw = data?['comparison'];
    return raw is Map ? Map<String, dynamic>.from(raw) : const {};
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
    if (error != null && (data == null || data!.isEmpty)) {
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
    final ingresosBase = data?['salesBase'] ??
        invoiceSummary?['subtotal'] ??
        salesMap['totalBase'] ??
        totals?['ingresosBase'] ??
        totals?['ingresosBaseTotal'];
    final ingresosTax = data?['salesVat'] ??
        invoiceSummary?['taxTotal'] ??
        salesMap['totalTax'] ??
        totals?['ingresosVat'] ??
        totals?['ingresosTax'];
    final ingresosCount = _readCount([
      data?['totalInvoices'],
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
    final filteredGastosBase = data?['purchaseBase'] != null
        ? (parseVatNum(data?['purchaseBase']) ?? 0)
        : (expenseSummary?['subtotal'] is num ||
                expenseSummary?['subtotal'] != null)
            ? (parseVatNum(expenseSummary?['subtotal']) ?? 0)
            : gastos.fold<double>(
                0,
                (sum, entry) => sum + _entryBaseValue(entry),
              );
    final filteredGastosTax = data?['purchaseVat'] != null
        ? (parseVatNum(data?['purchaseVat']) ?? 0)
        : (expenseSummary?['taxTotal'] is num ||
                expenseSummary?['taxTotal'] != null)
            ? (parseVatNum(expenseSummary?['taxTotal']) ?? 0)
            : gastos.fold<double>(
                0,
                (sum, entry) => sum + _entryTaxValue(entry),
              );
    final gastosCount = _readCount([
      data?['totalExpenses'],
      expenseSummary?['count'],
      purchasesMap['count'],
      totals?['gastosCount'],
      data?['expenseCount'],
    ]);
    final ivaValue = parseVatNum(data?['netVat']) ??
        ((parseVatNum(ingresosTax) ?? 0) - filteredGastosTax);
    final isPositive = ivaValue >= 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final salesBaseValue = parseVatNum(ingresosBase) ?? 0;
        final salesTaxValue = parseVatNum(ingresosTax) ?? 0;
        final purchaseBaseValue = filteredGastosBase.toDouble();
        final purchaseTaxValue = filteredGastosTax.toDouble();
        final previous = _previousPeriodData();
        final comparison = _comparisonData();
        final rawComparisonAvailable =
            data?['comparisonAvailable'] ?? comparison['comparisonAvailable'];
        final comparisonAvailable =
            rawComparisonAvailable is bool ? rawComparisonAvailable : null;
        final previousSalesTax = parseVatNum(
          data?['previousSalesVat'] ??
              previous['salesTax'] ??
              previous['salesVat'] ??
              previous['ventasTax'] ??
              previous['taxTotalSales'] ??
              previous['outputVat'],
        );
        final previousPurchaseTax = parseVatNum(
          data?['previousPurchaseVat'] ??
              previous['purchaseTax'] ??
              previous['purchaseVat'] ??
              previous['comprasTax'] ??
              previous['taxTotalPurchases'] ??
              previous['inputVat'],
        );
        final previousNetVat = parseVatNum(
          data?['previousNetVat'] ??
              previous['netVat'] ??
              previous['ivaValue'] ??
              previous['netTax'],
        );
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          children: [
            if (error != null) ...[
              _VatInlineNotice(message: error!, tone: _VatNoticeTone.warning),
              const SizedBox(height: 8),
            ],
            _VatComparisonChartCard(
              salesBase: salesBaseValue,
              salesTax: salesTaxValue,
              purchaseBase: purchaseBaseValue,
              purchaseTax: purchaseTaxValue,
              netVat: ivaValue,
              previousSalesTax: previousSalesTax,
              previousPurchaseTax: previousPurchaseTax,
              previousNetVat: previousNetVat,
              salesVatChangePercent:
                  parseVatNum(comparison['salesVatChangePercent']),
              purchaseVatChangePercent:
                  parseVatNum(comparison['purchaseVatChangePercent']),
              netVatChangePercent:
                  parseVatNum(comparison['netVatChangePercent']),
              comparisonAvailable: comparisonAvailable,
              previousQuarterLabel:
                  (comparison['previousQuarter'] ?? '').toString(),
              insights: _insights(),
              totalInvoices: ingresosCount,
              totalExpenses: gastosCount,
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
  final double? previousSalesTax;
  final double? previousPurchaseTax;
  final double? previousNetVat;
  final double? salesVatChangePercent;
  final double? purchaseVatChangePercent;
  final double? netVatChangePercent;
  final bool? comparisonAvailable;
  final String previousQuarterLabel;
  final List<Map<String, dynamic>> insights;
  final int? totalInvoices;
  final int? totalExpenses;
  final bool isPositive;

  const _VatComparisonChartCard({
    required this.salesBase,
    required this.salesTax,
    required this.purchaseBase,
    required this.purchaseTax,
    required this.netVat,
    this.previousSalesTax,
    this.previousPurchaseTax,
    this.previousNetVat,
    this.salesVatChangePercent,
    this.purchaseVatChangePercent,
    this.netVatChangePercent,
    this.comparisonAvailable,
    this.previousQuarterLabel = '',
    this.insights = const [],
    this.totalInvoices,
    this.totalExpenses,
    required this.isPositive,
  });

  String? _deltaLabel(double current, double? previous, double? provided) {
    if (provided != null) {
      final sign = provided >= 0 ? '+' : '-';
      return '$sign${provided.abs().toStringAsFixed(1)}% vs trim. anterior';
    }
    if (previous == null || previous.abs() < 0.01) return null;
    final delta = ((current - previous) / previous.abs()) * 100;
    final sign = delta >= 0 ? '+' : '-';
    return '$sign${delta.abs().toStringAsFixed(1)}% vs trim. anterior';
  }

  void _nudgeToDetails(BuildContext context) {
    final scrollable = Scrollable.maybeOf(context);
    final position = scrollable?.position;
    if (position == null) return;
    final target = (position.pixels + 300).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    position.animateTo(
      target.toDouble(),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final totalSales = salesBase + salesTax;
    final totalPurchases = purchaseBase + purchaseTax;
    final offsetRatio = salesTax.abs() < 0.01
        ? 0.0
        : (purchaseTax / salesTax * 100).clamp(0, 999).toDouble();
    final balanced = netVat.abs() <= (salesTax.abs() * 0.02).clamp(50, 500);
    final insightColor = balanced
        ? cs.primary
        : isPositive
            ? cs.error
            : cs.tertiary;
    final outcomeTitle = balanced
        ? 'IVA prácticamente equilibrado'
        : isPositive
            ? 'IVA a pagar'
            : 'IVA a devolver';
    final insightText = balanced
        ? 'Ventas y compras están casi compensadas este trimestre.'
        : isPositive
            ? 'Las compras deducibles compensan el ${offsetRatio.toStringAsFixed(0)}% del IVA repercutido.'
            : 'Las compras deducibles superan el IVA repercutido.';
    final hasComparison = comparisonAvailable == true;
    final salesDelta = hasComparison
        ? _deltaLabel(salesTax, previousSalesTax, salesVatChangePercent)
        : null;
    final purchaseDelta = hasComparison
        ? _deltaLabel(
            purchaseTax, previousPurchaseTax, purchaseVatChangePercent)
        : null;
    final netDelta = hasComparison
        ? _deltaLabel(netVat.abs(), previousNetVat?.abs(), netVatChangePercent)
        : null;
    final chartData = [
      _VatChartDatum(
        label: 'Base imponible',
        sales: salesBase,
        purchases: purchaseBase,
      ),
      _VatChartDatum(
        label: 'IVA',
        sales: salesTax,
        purchases: purchaseTax,
      ),
      _VatChartDatum(
        label: 'Total factura',
        sales: totalSales,
        purchases: totalPurchases,
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
                    'Ventas repercuten IVA, compras lo compensan. Revisa el neto para decidir el pago.',
                    style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _VatMetricChip(
                    label: 'Ventas IVA',
                    value: formatVatAmount(salesTax),
                    helper: salesDelta ?? 'IVA repercutido',
                    actionLabel: 'Ver facturas emitidas',
                    color: cs.primary,
                    prominent: true,
                    onTap: () => _nudgeToDetails(context),
                  ),
                  _VatMetricChip(
                    label: 'Compras IVA',
                    value: formatVatAmount(purchaseTax),
                    helper: purchaseDelta ?? 'IVA deducible',
                    actionLabel: 'Ver gastos deducibles',
                    color: cs.tertiary,
                    onTap: () => _nudgeToDetails(context),
                  ),
                  _VatMetricChip(
                    label: isPositive ? 'Neto a pagar' : 'Neto a devolver',
                    value: formatVatAmount(netVat),
                    helper: netDelta ?? 'Resultado fiscal',
                    actionLabel: 'Ver detalle fiscal',
                    color: insightColor,
                    prominent: true,
                    onTap: () => _nudgeToDetails(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: insightColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: insightColor.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.account_balance_outlined
                      : Icons.savings_outlined,
                  size: 16,
                  color: insightColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$outcomeTitle: ${formatVatAmount(netVat.abs())}',
                        style: t.bodySmall.copyWith(
                          color: insightColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        insightText,
                        style: t.bodySmall.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _MiniInsightPill(
                  label: 'Reduce pago',
                  value: formatVatAmount(purchaseTax),
                  color: cs.tertiary,
                ),
              ],
            ),
          ),
          if (comparisonAvailable != null) ...[
            const SizedBox(height: 8),
            _QuarterComparisonStrip(
              previousQuarterLabel: previousQuarterLabel,
              salesChange: salesVatChangePercent,
              purchaseChange: purchaseVatChangePercent,
              netChange: netVatChangePercent,
              comparisonAvailable: comparisonAvailable!,
            ),
          ],
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final insight in insights.take(2))
                  _VatInsightBanner(
                    message: insight['message'].toString(),
                    type: (insight['type'] ?? '').toString(),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MiniInsightPill(
                label: 'Base ventas',
                value: formatVatAmount(salesBase),
                color: cs.primary,
              ),
              _MiniInsightPill(
                label: 'Base compras',
                value: formatVatAmount(purchaseBase),
                color: cs.tertiary,
              ),
              _MiniInsightPill(
                label: 'Facturas',
                value: '${totalInvoices ?? 0}',
                color: cs.primary,
              ),
              _MiniInsightPill(
                label: 'Gastos',
                value: '${totalExpenses ?? 0}',
                color: cs.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
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
                  name: 'Ventas emitidas',
                  dataSource: chartData,
                  xValueMapper: (datum, _) => datum.label,
                  yValueMapper: (datum, _) => datum.sales,
                  color: cs.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  width: 0.34,
                ),
                ColumnSeries<_VatChartDatum, String>(
                  name: 'Compras deducibles',
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
  final String? helper;
  final String? actionLabel;
  final Color color;
  final bool prominent;
  final VoidCallback? onTap;

  const _VatMetricChip({
    required this.label,
    required this.value,
    this.helper,
    this.actionLabel,
    required this.color,
    this.prominent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Tooltip(
      message: actionLabel ?? label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: prominent ? 12 : 10,
            vertical: prominent ? 9 : 8,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: prominent ? 0.12 : 0.075),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: prominent ? 0.34 : 0.22),
            ),
            boxShadow: prominent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: t.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: prominent ? 13 : 12,
                  letterSpacing: -0.15,
                ),
              ),
              if ((helper ?? '').isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  helper!,
                  style: t.bodySmall.copyWith(
                    color: color.withValues(alpha: 0.72),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if ((actionLabel ?? '').isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: t.bodySmall.copyWith(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_downward_rounded, size: 10, color: color),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInsightPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniInsightPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: t.bodySmall.copyWith(
              color: color.withValues(alpha: 0.78),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: t.bodySmall.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuarterComparisonStrip extends StatelessWidget {
  final String previousQuarterLabel;
  final double? salesChange;
  final double? purchaseChange;
  final double? netChange;
  final bool comparisonAvailable;

  const _QuarterComparisonStrip({
    required this.previousQuarterLabel,
    required this.salesChange,
    required this.purchaseChange,
    required this.netChange,
    required this.comparisonAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    if (!comparisonAvailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                'No hay datos del trimestre anterior para comparar.',
                style: t.bodySmall.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
          ),
          child: Text(
            'vs ${previousQuarterLabel.isEmpty ? 'trimestre anterior' : previousQuarterLabel}',
            style: t.bodySmall.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
        _DeltaChip(label: 'Ventas IVA', value: salesChange),
        _DeltaChip(label: 'Compras IVA', value: purchaseChange),
        _DeltaChip(label: 'Neto IVA', value: netChange, netMeaning: true),
      ],
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final String label;
  final double? value;
  final bool netMeaning;

  const _DeltaChip({
    required this.label,
    required this.value,
    this.netMeaning = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final hasValue = value != null;
    final positive = (value ?? 0) >= 0;
    final color = !hasValue
        ? cs.onSurfaceVariant
        : positive
            ? (netMeaning ? cs.error : cs.tertiary)
            : (netMeaning ? cs.tertiary : const Color(0xFFD97706));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            !hasValue
                ? Icons.remove_rounded
                : positive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ${hasValue ? '${positive ? '+' : '-'}${value!.abs().toStringAsFixed(1)}%' : 'Sin datos'}',
            style: t.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _VatInsightBanner extends StatelessWidget {
  final String message;
  final String type;

  const _VatInsightBanner({
    required this.message,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final lower = type.toLowerCase();
    final color = lower.contains('warn')
        ? const Color(0xFFD97706)
        : lower.contains('error')
            ? cs.error
            : cs.primary;
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 14, color: color),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              message,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _VatNoticeTone { warning }

class _VatInlineNotice extends StatelessWidget {
  final String message;
  final _VatNoticeTone tone;

  const _VatInlineNotice({
    required this.message,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = AppTypography.of(context);
    final color =
        tone == _VatNoticeTone.warning ? const Color(0xFFD97706) : cs.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: t.bodySmall.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
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
