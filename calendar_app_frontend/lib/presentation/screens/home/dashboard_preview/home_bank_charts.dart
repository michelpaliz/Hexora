import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_widgets.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_formatters.dart';
import 'package:hexora/services/statements/statements_api.dart';

/// Home-dashboard row that reuses the bank analytics charts
/// (income vs expense trend + income/expense split donut) for the latest year
/// with imported statements.
///
/// Renders nothing when the group has no bank data, so the home stays clean for
/// groups that do not use banking.
class HomeBankCharts extends StatefulWidget {
  const HomeBankCharts({
    super.key,
    required this.groupId,
    required this.isEs,
    required this.twoCol,
    this.onOpenBank,
  });

  final String groupId;
  final bool isEs;
  final bool twoCol;
  final VoidCallback? onOpenBank;

  @override
  State<HomeBankCharts> createState() => _HomeBankChartsState();
}

class _HomeBankChartsState extends State<HomeBankCharts>
    with AutomaticKeepAliveClientMixin {
  static const _surface = Colors.white;
  static const _border = Color(0xFFE6E9F2);
  static const _ink = Color(0xFF1C2435);
  static const _muted = Color(0xFF8A93A6);
  static const _blue = Color(0xFF2F6BFF);
  static const _green = Color(0xFF17B26A);
  static const _red = Color(0xFFE65B73);

  static const _requestTimeout = Duration(seconds: 20);

  late StatementsApi _api;
  int _loadId = 0;

  bool _loading = true;
  bool _hidden = false;
  int? _year;
  List<Map<String, dynamic>> _months = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _api = StatementsApi(groupId: widget.groupId);
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeBankCharts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _api = StatementsApi(groupId: widget.groupId);
      _load();
      setState(() {});
    }
  }

  /// Lean loader for the home screen. Unlike the bank analytics controller it
  /// fetches every batch summary in parallel (not one after another), skips
  /// transaction entries / status / comparison, and times out instead of
  /// spinning forever.
  Future<void> _load() async {
    final id = ++_loadId;
    // Plain assignment: this also runs from initState, before the first build.
    _loading = true;
    _hidden = false;
    final sw = Stopwatch()..start();
    void log(String msg) {
      if (kDebugMode) {
        debugPrint('[HomeBankCharts] $msg (${sw.elapsedMilliseconds} ms)');
      }
    }

    try {
      final batches = await _api.listImports().timeout(_requestTimeout);
      final ids = batches
          .map((b) => (b['batchId'] ?? b['_id'] ?? b['id'])?.toString())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      log('listImports → ${ids.length} batches');
      if (ids.isEmpty) return _finish(id, hidden: true);

      // Pass 1: all-years summary per batch, in parallel.
      final overall = await _summaries(ids);
      log('summary (all years) x${ids.length}');
      final years = <int>{
        for (final res in overall)
          for (final row in _list(res['years']))
            if (int.tryParse(row['year']?.toString() ?? '') case final y?) y,
      };
      if (years.isEmpty) return _finish(id, hidden: true);
      final year = years.reduce((a, b) => a > b ? a : b);

      // Use the months from pass 1 if the server already returned them for
      // this year; otherwise run pass 2 scoped to the year.
      var months = _aggregateMonths(overall, year);
      if (months.isEmpty) {
        months = _aggregateMonths(await _summaries(ids, year: year), year);
        log('summary ($year) x${ids.length}');
      }
      if (!mounted || id != _loadId) return;
      setState(() {
        _year = year;
        _months = months;
      });
      _finish(id, hidden: months.isEmpty);
    } catch (e) {
      log('failed: $e');
      _finish(id, hidden: true);
    }
  }

  void _finish(int id, {required bool hidden}) {
    if (!mounted || id != _loadId) return;
    setState(() {
      _loading = false;
      _hidden = hidden;
    });
  }

  Future<List<Map<String, dynamic>>> _summaries(
    List<String> ids, {
    int? year,
  }) async {
    final results = await Future.wait(ids.map((batchId) async {
      try {
        return await _api
            .analyticsSummary(batchId: batchId, year: year, top: 1)
            .timeout(_requestTimeout);
      } catch (e) {
        if (kDebugMode) debugPrint('[HomeBankCharts] $batchId failed: $e');
        return null;
      }
    }));
    return results.whereType<Map<String, dynamic>>().toList();
  }

  static List<Map<String, dynamic>> _list(dynamic raw) =>
      (raw is List ? raw : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  static List<Map<String, dynamic>> _aggregateMonths(
    List<Map<String, dynamic>> summaries,
    int year,
  ) {
    final byMonth = <int, Map<String, num>>{};
    for (final res in summaries) {
      for (final row in _list(res['months'])) {
        if (int.tryParse(row['year']?.toString() ?? '') != year) continue;
        final m = int.tryParse(row['month']?.toString() ?? '');
        if (m == null) continue;
        final agg = byMonth.putIfAbsent(
            m, () => {'income': 0, 'expense': 0, 'count': 0});
        agg['income'] = agg['income']! + ((row['income'] as num?) ?? 0);
        agg['expense'] = agg['expense']! + ((row['expense'] as num?) ?? 0);
        agg['count'] = agg['count']! + ((row['count'] as num?) ?? 0);
      }
    }
    final keys = byMonth.keys.toList()..sort();
    return [
      for (final m in keys)
        {
          'year': year,
          'month': m,
          'income': byMonth[m]!['income'],
          'expense': byMonth[m]!['expense'],
          'net': byMonth[m]!['income']! - byMonth[m]!['expense']!,
          'count': byMonth[m]!['count'],
        },
    ];
  }

  String _monthLabel(Map<String, dynamic> row) {
    final month = int.tryParse(row['month']?.toString() ?? '');
    if (month == null || month < 1 || month > 12) {
      return row['year']?.toString() ?? '-';
    }
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.MMM(locale).format(DateTime(2000, month));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Hide entirely when there is nothing to show (no imports, error, or
    // timeout).
    if (_hidden) return const SizedBox.shrink();

    final base = widget.isEs ? 'Movimientos bancarios' : 'Bank movements';
    final trend = _panel(
      title: _year == null ? base : '$base · $_year',
      height: 320,
      child: _loading
          ? const _ChartPlaceholder()
          : AnalyticsTrendChart(rows: _months, labelBuilder: _monthLabel),
    );
    final split = _panel(
      title: widget.isEs ? 'Ingresos vs gastos' : 'Income vs expenses',
      height: 320,
      child: _loading ? const _ChartPlaceholder() : _buildSplit(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: widget.twoCol
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: trend),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: split),
              ],
            )
          : Column(children: [trend, const SizedBox(height: 18), split]),
    );
  }

  Widget _buildSplit() {
    num income = 0, expense = 0;
    for (final m in _months) {
      income += (m['income'] as num?) ?? 0;
      expense += (m['expense'] as num?) ?? 0;
    }
    final incomeLabel = StatementsFormatters.formatCurrency(context, income);
    final expenseLabel = StatementsFormatters.formatCurrency(context, expense);
    final netLabel =
        StatementsFormatters.formatCurrency(context, income - expense);
    return AnalyticsDonutChart(
      slices: [
        AnalyticsDonutSlice(
          label: widget.isEs ? 'Ingresos' : 'Income',
          value: income,
          color: _green,
          legendValue: incomeLabel,
          tooltipValue: incomeLabel,
        ),
        AnalyticsDonutSlice(
          label: widget.isEs ? 'Gastos' : 'Expenses',
          value: expense,
          color: _red,
          legendValue: expenseLabel,
          tooltipValue: expenseLabel,
        ),
      ],
      centerLabel: widget.isEs ? 'Neto' : 'Net',
      centerValue: netLabel,
    );
  }

  Widget _panel({
    required String title,
    required double height,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.onOpenBank != null)
                InkWell(
                  onTap: widget.onOpenBank,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isEs ? 'Ver banco' : 'Open bank',
                          style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: _blue),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _HomeBankChartsState._muted,
        ),
      ),
    );
  }
}
