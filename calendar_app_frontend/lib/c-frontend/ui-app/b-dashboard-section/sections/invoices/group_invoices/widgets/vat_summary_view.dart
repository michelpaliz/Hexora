import 'package:flutter/material.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

double? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return double.tryParse(raw.replaceAll(',', '.'));
}

String _formatAmount(dynamic value) {
  final parsed = _parseNum(value);
  if (parsed == null) return value?.toString() ?? '-';
  return parsed.toStringAsFixed(2);
}

String _formatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

(DateTime, DateTime) _quarterRangeDates(int year, int quarter) {
  final startMonth = 1 + (quarter - 1) * 3;
  final start = DateTime(year, startMonth, 1);
  final end = DateTime(year, startMonth + 3, 0);
  return (start, end);
}

class VatSummaryView extends StatefulWidget {
  final VatSummaryApi api;
  final String? groupId;

  const VatSummaryView({
    super.key,
    required this.api,
    this.groupId,
  });

  @override
  State<VatSummaryView> createState() => _VatSummaryViewState();
}

class _VatSummaryViewState extends State<VatSummaryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _year = DateTime.now().year;
  final Map<int, Map<String, dynamic>> _data = {};
  final Map<int, String?> _errors = {};
  final Map<int, bool> _loading = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (_tabs.indexIsChanging) return;
      _ensureLoaded(_tabs.index + 1);
      if (mounted) setState(() {});
    });
    _ensureLoaded(1);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _ensureLoaded(int quarter) {
    if (_loading[quarter] == true || _data.containsKey(quarter)) return;
    _loadQuarter(quarter);
  }

  Future<void> _loadQuarter(int quarter) async {
    setState(() {
      _loading[quarter] = true;
      _errors[quarter] = null;
    });
    final range = _quarterRangeDates(_year, quarter);
    final from = _formatDate(range.$1);
    final to = _formatDate(range.$2);
    try {
      final data = await widget.api.getSummary(
        groupId: widget.groupId,
        from: from,
        to: to,
      );
      if (!mounted) return;
      setState(() => _data[quarter] = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errors[quarter] = e.toString());
    } finally {
      if (mounted) setState(() => _loading[quarter] = false);
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _year += delta;
      _data.clear();
      _errors.clear();
      _loading.clear();
    });
    _ensureLoaded(_tabs.index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final selectedQuarter = _tabs.index + 1;
    final rangeLabel = _quarterRangeLabel(
      context,
      year: _year,
      quarter: selectedQuarter,
    );
    final deadlineLabel = _quarterDeadlineLabel(
      context,
      year: _year,
      quarter: selectedQuarter,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.vatSummaryTitle,
                    style: t.titleLarge.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _year.toString(),
                        style: t.bodySmall.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.vatSummaryPrevYear,
                  onPressed: () => _changeYear(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: l.vatSummaryNextYear,
                  onPressed: () => _changeYear(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer.withOpacity(0.7),
                cs.secondaryContainer.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.event, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rangeLabel,
                  style: t.bodySmall.copyWith(color: cs.onPrimaryContainer),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 6),
              Text(
                deadlineLabel,
                style: t.bodySmall.copyWith(color: cs.onPrimaryContainer),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(color: cs.primary, width: 3),
          ),
          tabs: [
            Tab(text: l.vatSummaryQuarterQ1),
            Tab(text: l.vatSummaryQuarterQ2),
            Tab(text: l.vatSummaryQuarterQ3),
            Tab(text: l.vatSummaryQuarterQ4),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: List.generate(4, (index) {
              final quarter = index + 1;
              return _QuarterSummary(
                loading: _loading[quarter] == true,
                error: _errors[quarter],
                data: _data[quarter],
                onRetry: () => _loadQuarter(quarter),
              );
            }),
          ),
        ),
      ],
    );
  }
}

String _quarterRangeLabel(
  BuildContext context, {
  required int year,
  required int quarter,
}) {
  final l = AppLocalizations.of(context)!;
  String range;
  switch (quarter) {
    case 1:
      range = l.vatSummaryQuarterRangeQ1(year.toString());
      break;
    case 2:
      range = l.vatSummaryQuarterRangeQ2(year.toString());
      break;
    case 3:
      range = l.vatSummaryQuarterRangeQ3(year.toString());
      break;
    default:
      range = l.vatSummaryQuarterRangeQ4(year.toString());
  }
  return l.vatSummaryQuarterRangeLabel(quarter.toString(), range);
}

String _quarterDeadlineLabel(
  BuildContext context, {
  required int year,
  required int quarter,
}) {
  final l = AppLocalizations.of(context)!;
  switch (quarter) {
    case 1:
      return l.vatSummaryQuarterDeadlineQ1(year.toString());
    case 2:
      return l.vatSummaryQuarterDeadlineQ2(year.toString());
    case 3:
      return l.vatSummaryQuarterDeadlineQ3(year.toString());
    default:
      return l.vatSummaryQuarterDeadlineQ4((year + 1).toString());
  }
}

class _QuarterSummary extends StatelessWidget {
  final bool loading;
  final String? error;
  final Map<String, dynamic>? data;
  final VoidCallback onRetry;

  const _QuarterSummary({
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
    final ingresos = _entries('ingresos_by_client');
    final gastos = _entries('gastos_by_provider');
    final ivaResult = totals?['ivaResult'];
    final ivaValue = _parseNum(ivaResult) ?? 0;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _VatSectionCard(
          title: l.vatSummarySalesTitle,
          entries: ingresos,
          nameKey: 'clientName',
          idKey: 'clientId',
          totalBase: totals?['ingresosBase'],
          totalTax: totals?['ingresosVat'],
          accentColor: cs.primary,
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 10),
        _VatSectionCard(
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
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        ivaValue >= 0 ? cs.primaryContainer : cs.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ivaValue >= 0 ? Icons.south_west : Icons.north_east,
                    color: ivaValue >= 0
                        ? cs.onPrimaryContainer
                        : cs.onErrorContainer,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.vatSummaryNetTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        ivaValue >= 0 ? cs.primaryContainer : cs.errorContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatAmount(ivaResult),
                    style: t.bodySmall.copyWith(
                      color: ivaValue >= 0
                          ? cs.onPrimaryContainer
                          : cs.onErrorContainer,
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
  }
}

class _VatSectionCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> entries;
  final String nameKey;
  final String? idKey;
  final String? countKey;
  final dynamic totalBase;
  final dynamic totalTax;
  final Color accentColor;
  final IconData icon;

  const _VatSectionCard({
    required this.title,
    required this.entries,
    required this.nameKey,
    this.idKey,
    this.countKey,
    required this.totalBase,
    required this.totalTax,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasTotals =
        (_parseNum(totalBase) ?? 0) != 0 || (_parseNum(totalTax) ?? 0) != 0;
    return Card(
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
                    color: accentColor.withOpacity(0.16),
                    shape: BoxShape.circle,
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
                  final count = countKey == null
                      ? ''
                      : (entry[countKey]?.toString().trim() ?? '');
                  final base = _formatAmount(entry['baseTotal']);
                  final tax = _formatAmount(entry['vatTotal']);
                  final total = _formatAmount(entry['grandTotal']);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.surfaceContainerHigh),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              displayName,
                              if (count.isNotEmpty) '($count)',
                            ].join(' '),
                            style: t.bodySmall,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            _AmountChip(
                              label: l.vatSummaryBaseLabel,
                              value: base,
                              color: accentColor.withOpacity(0.12),
                              textColor: accentColor,
                            ),
                            _AmountChip(
                              label: l.vatSummaryTaxLabel,
                              value: tax,
                              color: cs.secondaryContainer,
                              textColor: cs.onSecondaryContainer,
                            ),
                            _AmountChip(
                              label: l.expenseUploadLinesTotalLabel,
                              value: total,
                              color: cs.primaryContainer,
                              textColor: cs.onPrimaryContainer,
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
                    _AmountChip(
                      label: l.vatSummaryBaseLabel,
                      value: _formatAmount(totalBase),
                      color: accentColor.withOpacity(0.12),
                      textColor: accentColor,
                    ),
                    _AmountChip(
                      label: l.vatSummaryTaxLabel,
                      value: _formatAmount(totalTax),
                      color: cs.secondaryContainer,
                      textColor: cs.onSecondaryContainer,
                    ),
                    _AmountChip(
                      label: l.expenseUploadLinesTotalLabel,
                      value: _formatAmount((_parseNum(totalBase) ?? 0) +
                          (_parseNum(totalTax) ?? 0)),
                      color: cs.primaryContainer,
                      textColor: cs.onPrimaryContainer,
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

class _AmountChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _AmountChip({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTypography.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
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
