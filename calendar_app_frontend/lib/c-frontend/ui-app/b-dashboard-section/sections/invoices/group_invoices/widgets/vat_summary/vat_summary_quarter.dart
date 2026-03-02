import 'package:flutter/material.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

import 'vat_summary_utils.dart';

class VatQuarterSummary extends StatelessWidget {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? data;
  final VoidCallback onRetry;

  const VatQuarterSummary({
    super.key,
    required this.loading,
    required this.error,
    required this.data,
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
    final ingresosByInvoice = _entries('ingresos_by_invoice');
    final ingresos = salesMap['byInvoice'] is List
        ? (salesMap['byInvoice'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : (ingresosByInvoice.isNotEmpty
            ? ingresosByInvoice
            : _entries('ingresos_by_client'));
    final gastos = _entries('gastos_by_provider');
    final ingresosBase = salesMap['totalBase'] ??
        totals?['ingresosBase'] ??
        totals?['ingresosBaseTotal'];
    final ingresosTax = salesMap['totalTax'] ??
        totals?['ingresosVat'] ??
        totals?['ingresosTax'];
    final ivaResult = totals?['ivaResult'];
    final ivaValue = parseVatNum(ivaResult) ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: VatSectionCard(
                      title: l.vatSummarySalesTitle,
                      entries: ingresos,
                      nameKey: 'invoiceNumber',
                      idKey: 'invoiceId',
                      secondaryNameKey: 'clientName',
                      totalBase: ingresosBase,
                      totalTax: ingresosTax,
                      accentColor: cs.primary,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: VatSectionCard(
                      title: l.vatSummaryPurchasesTitle,
                      entries: gastos,
                      nameKey: 'providerName',
                      idKey: 'providerId',
                      countKey: 'count',
                      totalBase: totals?['gastosBase'],
                      totalTax: totals?['gastosVat'],
                      accentColor: cs.tertiary,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              )
            else ...[
              VatSectionCard(
                title: l.vatSummarySalesTitle,
                entries: ingresos,
                nameKey: 'invoiceNumber',
                idKey: 'invoiceId',
                secondaryNameKey: 'clientName',
                totalBase: ingresosBase,
                totalTax: ingresosTax,
                accentColor: cs.primary,
                icon: Icons.trending_up,
              ),
              const SizedBox(height: 10),
              VatSectionCard(
                title: l.vatSummaryPurchasesTitle,
                entries: gastos,
                nameKey: 'providerName',
                idKey: 'providerId',
                countKey: 'count',
                totalBase: totals?['gastosBase'],
                totalTax: totals?['gastosVat'],
                accentColor: cs.tertiary,
                icon: Icons.shopping_bag_outlined,
              ),
            ],
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ivaValue >= 0 ? cs.primary : cs.error,
                        ),
                      ),
                      child: Icon(
                        ivaValue >= 0 ? Icons.south_west : Icons.north_east,
                        color: ivaValue >= 0 ? cs.primary : cs.error,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.vatSummaryNetTitle,
                        style:
                            t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: ivaValue >= 0 ? cs.primary : cs.error,
                        ),
                      ),
                      child: Text(
                        formatVatAmount(ivaResult),
                        style: t.bodySmall.copyWith(
                          color: ivaValue >= 0 ? cs.primary : cs.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class VatSectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> entries;
  final String nameKey;
  final String? idKey;
  final String? secondaryNameKey;
  final String? countKey;
  final List<String> invoiceNumberKeys;
  final dynamic totalBase;
  final dynamic totalTax;
  final Color accentColor;
  final IconData icon;

  const VatSectionCard({
    super.key,
    required this.title,
    required this.entries,
    required this.nameKey,
    this.idKey,
    this.secondaryNameKey,
    this.countKey,
    this.invoiceNumberKeys = const [],
    required this.totalBase,
    required this.totalTax,
    required this.accentColor,
    required this.icon,
  });

  List<String> _extractInvoiceNumbers(Map<String, dynamic> entry) {
    final collected = <String>{};

    for (final key in invoiceNumberKeys) {
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
    final hasTotals =
        (parseVatNum(totalBase) ?? 0) != 0 || (parseVatNum(totalTax) ?? 0) != 0;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor),
                  ),
                  child: Icon(icon, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty && !hasTotals)
              Text(l.vatSummaryNoRates, style: t.bodySmall)
            else
              Column(
                children: entries.map((entry) {
                  final name = entry[nameKey]?.toString().trim() ?? '';
                  final fallbackId = idKey == null
                      ? ''
                      : (entry[idKey]?.toString().trim() ?? '');
                  final displayName = name.isNotEmpty
                      ? name
                      : (fallbackId.isNotEmpty ? 'ID: $fallbackId' : '-');
                  final secondaryName = secondaryNameKey == null
                      ? ''
                      : (entry[secondaryNameKey]?.toString().trim() ?? '');
                  final invoiceNumbers = invoiceNumberKeys.isEmpty
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
                  final count = countKey == null
                      ? ''
                      : (entry[countKey]?.toString().trim() ?? '');
                  final base = formatVatAmount(
                      entry['baseTotal'] ?? entry['subtotal'] ?? entry['base']);
                  final tax = formatVatAmount(
                      entry['vatTotal'] ?? entry['tax'] ?? entry['vat']);
                  final total = formatVatAmount(
                      entry['grandTotal'] ?? entry['total'] ?? entry['amount']);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: t.bodySmall,
                              ),
                              if (secondaryName.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  secondaryName,
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (count.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '($count)',
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (invoiceNumbers.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${l.invoiceNumberLabel}: ${invoiceNumbers.join(', ')}',
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                              if (issueDateLabel.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${l.invoiceDateLabel}: $issueDateLabel',
                                  style: t.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            VatAmountChip(
                              label: l.vatSummaryBaseLabel,
                              value: base,
                              color: Colors.transparent,
                              textColor: accentColor,
                              borderColor: accentColor,
                            ),
                            VatAmountChip(
                              label: l.vatSummaryTaxLabel,
                              value: tax,
                              color: Colors.transparent,
                              textColor: cs.onSurface,
                              borderColor:
                                  cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                            VatAmountChip(
                              label: l.expenseUploadLinesTotalLabel,
                              value: total,
                              color: Colors.transparent,
                              textColor: cs.onSurface,
                              borderColor:
                                  cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.vatSummaryTotalsLabel,
                    style: t.bodySmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    VatAmountChip(
                      label: l.vatSummaryBaseLabel,
                      value: formatVatAmount(totalBase),
                      color: Colors.transparent,
                      textColor: accentColor,
                      borderColor: accentColor,
                    ),
                    VatAmountChip(
                      label: l.vatSummaryTaxLabel,
                      value: formatVatAmount(totalTax),
                      color: Colors.transparent,
                      textColor: cs.onSurface,
                      borderColor: cs.outlineVariant.withValues(alpha: 0.6),
                    ),
                    VatAmountChip(
                      label: l.expenseUploadLinesTotalLabel,
                      value: formatVatAmount((parseVatNum(totalBase) ?? 0) +
                          (parseVatNum(totalTax) ?? 0)),
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
