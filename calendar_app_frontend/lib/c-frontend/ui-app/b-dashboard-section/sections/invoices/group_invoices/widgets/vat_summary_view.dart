import 'package:flutter/material.dart';
import 'package:hexora/b-backend/vat/vat_summary_api.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

class VatSummaryView extends StatefulWidget {
  final VatSummaryApi api;

  const VatSummaryView({
    super.key,
    required this.api,
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
    try {
      final data = await widget.api.getSummary(year: _year, quarter: quarter);
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.vatSummaryTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: l.vatSummaryPrevYear,
                  onPressed: () => _changeYear(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  _year.toString(),
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
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
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.event, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rangeLabel,
                  style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.schedule, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                deadlineLabel,
                style: t.bodySmall.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabs,
          labelColor: cs.onSurface,
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
                quarter: quarter,
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
  final int quarter;
  final bool loading;
  final String? error;
  final Map<String, dynamic>? data;
  final VoidCallback onRetry;

  const _QuarterSummary({
    required this.quarter,
    required this.loading,
    required this.error,
    required this.data,
    required this.onRetry,
  });

  Map<String, dynamic>? _section(String key) {
    final raw = data?[key];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  List<Map<String, dynamic>> _rates(Map<String, dynamic>? section) {
    final raw = section?['rates'];
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

    final sales = _section('sales');
    final purchases = _section('purchases');
    final netVat = data?['netVat'];

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        _VatSectionCard(
          title: l.vatSummarySalesTitle,
          rates: _rates(sales),
          totalBase: sales?['totalBase'],
          totalTax: sales?['totalTax'],
        ),
        const SizedBox(height: 10),
        _VatSectionCard(
          title: l.vatSummaryPurchasesTitle,
          rates: _rates(purchases),
          totalBase: purchases?['totalBase'],
          totalTax: purchases?['totalTax'],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.vatSummaryNetTitle,
                    style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  netVat?.toString() ?? '-',
                  style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700),
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
  final List<Map<String, dynamic>> rates;
  final dynamic totalBase;
  final dynamic totalTax;

  const _VatSectionCard({
    required this.title,
    required this.rates,
    required this.totalBase,
    required this.totalTax,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = AppTypography.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: t.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (rates.isEmpty)
              Text(l.vatSummaryNoRates, style: t.bodySmall)
            else
              Column(
                children: rates.map((rate) {
                  final r = rate['rate']?.toString() ?? '-';
                  final base = rate['base']?.toString() ?? '-';
                  final tax = rate['tax']?.toString() ?? '-';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${l.vatSummaryRateLabel} $r',
                            style: t.bodySmall,
                          ),
                        ),
                        Text(
                          '${l.vatSummaryBaseLabel} $base',
                          style: t.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${l.vatSummaryTaxLabel} $tax',
                          style: t.bodySmall,
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
                Text(
                  '${l.vatSummaryBaseLabel} ${totalBase ?? '-'}',
                  style: t.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  '${l.vatSummaryTaxLabel} ${totalTax ?? '-'}',
                  style: t.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
