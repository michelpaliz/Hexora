import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';

enum StatementsAnalyticsPeriodMode {
  calendarMonth,
  settlementWindow,
}

enum StatementsAnalyticsCompareMode {
  both,
  calendarOnly,
  settlementOnly,
  delta,
}

class StatementsAnalyticsController extends ChangeNotifier {
  StatementsAnalyticsController({StatementsApi? api}) : _api = api ?? StatementsApi();

  final StatementsApi _api;

  bool loadingBatches = false;
  String? batchesError;
  List<Map<String, dynamic>> batches = const [];

  bool loadingSummary = false;
  String? summaryError;
  Map<String, dynamic> summary = const {};

  String? selectedBatchId;
  int? selectedYear;
  int? selectedMonth;
  int top = 20;
  StatementsAnalyticsPeriodMode periodMode =
      StatementsAnalyticsPeriodMode.calendarMonth;
  int settlementStartDay = 26;
  int settlementEndDay = 20;
  StatementsAnalyticsCompareMode compareMode =
      StatementsAnalyticsCompareMode.both;

  bool loadingCompare = false;
  String? compareError;
  List<StatementsAnalyticsCompareRow> compareRows = const [];

  List<Map<String, dynamic>> get years =>
      (summary['years'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> get months =>
      (summary['months'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> get topExpense =>
      ((summary['topMerchants'] is Map
                  ? (summary['topMerchants'] as Map)['expense']
                  : null) as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  List<Map<String, dynamic>> get topIncome =>
      ((summary['topMerchants'] is Map
                  ? (summary['topMerchants'] as Map)['income']
                  : null) as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  Future<void> loadBatches() async {
    if (loadingBatches) return;
    loadingBatches = true;
    batchesError = null;
    notifyListeners();
    try {
      batches = await _api.listImports();
      if (selectedBatchId == null && batches.isNotEmpty) {
        selectedBatchId = 'all';
        await fetchSummary();
      }
    } catch (e) {
      batchesError = e.toString();
    } finally {
      loadingBatches = false;
      notifyListeners();
    }
  }

  Future<void> selectBatch(String? batchId) async {
    if (batchId == null || batchId.isEmpty) return;
    selectedBatchId = batchId;
    selectedYear = null;
    selectedMonth = null;
    await fetchSummary();
    await fetchComparison();
  }

  Future<void> setYear(int? year) async {
    selectedYear = year;
    selectedMonth = null;
    await fetchSummary();
    await fetchComparison();
  }

  Future<void> setMonth(int? month) async {
    selectedMonth = month;
    await fetchSummary();
  }

  Future<void> setPeriodMode(StatementsAnalyticsPeriodMode mode) async {
    periodMode = mode;
    await fetchSummary();
    await fetchComparison();
  }

  void setCompareMode(StatementsAnalyticsCompareMode mode) {
    compareMode = mode;
    notifyListeners();
  }

  Future<void> setSettlementStartDay(int day) async {
    settlementStartDay = _normalizeDay(day);
    await fetchSummary();
    await fetchComparison();
  }

  Future<void> setSettlementEndDay(int day) async {
    settlementEndDay = _normalizeDay(day);
    await fetchSummary();
    await fetchComparison();
  }

  Future<void> setTop(int value) async {
    top = value;
    await fetchSummary();
  }

  Future<void> fetchSummary() async {
    if (selectedBatchId == null) return;
    loadingSummary = true;
    summaryError = null;
    notifyListeners();
    try {
      final settlementRange = _settlementRange();
      final dateFrom = settlementRange == null
          ? null
          : _dateOnly(settlementRange.start);
      final dateTo =
          settlementRange == null ? null : _dateOnly(settlementRange.end);
      final useDateRange = dateFrom != null && dateTo != null;
      if (selectedBatchId == 'all') {
        summary = await _fetchSummaryAllBatches(
          dateFrom: dateFrom,
          dateTo: dateTo,
          useDateRange: useDateRange,
        );
      } else {
        summary = await _api.analyticsSummary(
          batchId: selectedBatchId!,
          year: useDateRange ? null : selectedYear,
          month: useDateRange ? null : selectedMonth,
          top: top,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
      }
    } catch (e) {
      summaryError = e.toString();
    } finally {
      loadingSummary = false;
      notifyListeners();
    }
  }

  Future<void> fetchComparison() async {
    if (selectedBatchId == null || selectedYear == null) {
      compareRows = const [];
      compareError = null;
      notifyListeners();
      return;
    }
    if (loadingCompare) return;
    loadingCompare = true;
    compareError = null;
    notifyListeners();
    try {
      final year = selectedYear!;
      final List<StatementsAnalyticsCompareRow> rows = [];
      for (var month = 1; month <= 12; month += 1) {
        final calendarRange = _calendarRange(year, month);
        final settlementRange = _settlementWindowRange(year, month);
        final calendarTotals = await _fetchRangeTotals(
          dateFrom: _dateOnly(calendarRange.start),
          dateTo: _dateOnly(calendarRange.end),
        );
        final settlementTotals = await _fetchRangeTotals(
          dateFrom: _dateOnly(settlementRange.start),
          dateTo: _dateOnly(settlementRange.end),
        );
        rows.add(
          StatementsAnalyticsCompareRow(
            year: year,
            month: month,
            calendarStart: calendarRange.start,
            calendarEnd: calendarRange.end,
            settlementStart: settlementRange.start,
            settlementEnd: settlementRange.end,
            calendarTotals: calendarTotals,
            settlementTotals: settlementTotals,
          ),
        );
      }
      compareRows = rows;
    } catch (e) {
      compareError = e.toString();
    } finally {
      loadingCompare = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _fetchSummaryAllBatches({
    String? dateFrom,
    String? dateTo,
    required bool useDateRange,
  }) async {
    final Map<int, _AggRow> years = {};
    final Map<String, _AggRow> months = {};
    final Map<String, _AggRow> expenseMerchants = {};
    final Map<String, _AggRow> incomeMerchants = {};

    final topFetch = top < 100 ? 100 : top;

    for (final batch in batches) {
      final batchId =
          (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString();
      if (batchId == null || batchId.isEmpty) continue;
      final res = await _api.analyticsSummary(
        batchId: batchId,
        year: useDateRange ? null : selectedYear,
        month: useDateRange ? null : selectedMonth,
        top: topFetch,
        dateFrom: dateFrom,
        dateTo: dateTo,
      );
      final yearsList = (res['years'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      for (final row in yearsList) {
        final year = int.tryParse(row['year']?.toString() ?? '');
        if (year == null) continue;
        years.putIfAbsent(year, () => _AggRow());
        years[year]!.add(row);
      }
      final monthsList = (res['months'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      for (final row in monthsList) {
        final year = row['year']?.toString() ?? '';
        final month = row['month']?.toString() ?? '';
        if (year.isEmpty || month.isEmpty) continue;
        final key = '$year-$month';
        months.putIfAbsent(key, () => _AggRow(year: year, month: month));
        months[key]!.add(row);
      }
      final topMerchants = res['topMerchants'];
      if (topMerchants is Map) {
        final expenseList = (topMerchants['expense'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final row in expenseList) {
          final merchant = row['merchant']?.toString() ?? '';
          if (merchant.isEmpty) continue;
          expenseMerchants.putIfAbsent(merchant, () => _AggRow(merchant: merchant));
          expenseMerchants[merchant]!.add(row, isMerchant: true);
        }
        final incomeList = (topMerchants['income'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final row in incomeList) {
          final merchant = row['merchant']?.toString() ?? '';
          if (merchant.isEmpty) continue;
          incomeMerchants.putIfAbsent(merchant, () => _AggRow(merchant: merchant));
          incomeMerchants[merchant]!.add(row, isMerchant: true);
        }
      }
    }

    final yearsOut = years.entries
        .map((e) => e.value.toYearMap(e.key))
        .toList()
      ..sort((a, b) => (a['year'] as int).compareTo(b['year'] as int));
    final monthsOut = months.values.map((e) => e.toMonthMap()).toList()
      ..sort((a, b) {
        final ay = int.tryParse(a['year']?.toString() ?? '') ?? 0;
        final by = int.tryParse(b['year']?.toString() ?? '') ?? 0;
        if (ay != by) return ay.compareTo(by);
        final am = int.tryParse(a['month']?.toString() ?? '') ?? 0;
        final bm = int.tryParse(b['month']?.toString() ?? '') ?? 0;
        return am.compareTo(bm);
      });
    final topExpense = expenseMerchants.values
        .map((e) => e.toMerchantMap())
        .toList()
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
    final topIncome = incomeMerchants.values
        .map((e) => e.toMerchantMap())
        .toList()
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));

    return {
      'batchId': 'all',
      'years': yearsOut,
      'months': monthsOut,
      'topMerchants': {
        'expense': topExpense.take(top).toList(),
        'income': topIncome.take(top).toList(),
      },
    };
  }

  ({DateTime start, DateTime end})? settlementRange() => _settlementRange();

  ({DateTime start, DateTime end})? _settlementRange() {
    if (periodMode != StatementsAnalyticsPeriodMode.settlementWindow) {
      return null;
    }
    if (selectedYear == null || selectedMonth == null) return null;
    final startDay = _clampDay(
      settlementStartDay,
      selectedYear!,
      selectedMonth!,
    );
    final startDate = DateTime(selectedYear!, selectedMonth!, startDay);
    final nextMonth = selectedMonth == 12 ? 1 : selectedMonth! + 1;
    final nextYear = selectedMonth == 12 ? selectedYear! + 1 : selectedYear!;
    final endDay = _clampDay(settlementEndDay, nextYear, nextMonth);
    final endDate = DateTime(nextYear, nextMonth, endDay);
    return (start: startDate, end: endDate);
  }

  ({DateTime start, DateTime end}) _calendarRange(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    return (start: start, end: end);
  }

  ({DateTime start, DateTime end}) _settlementWindowRange(int year, int month) {
    final startDay = _clampDay(settlementStartDay, year, month);
    final start = DateTime(year, month, startDay);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDay = _clampDay(settlementEndDay, nextYear, nextMonth);
    final end = DateTime(nextYear, nextMonth, endDay);
    return (start: start, end: end);
  }

  int _normalizeDay(int day) {
    if (day < 1) return 1;
    if (day > 31) return 31;
    return day;
  }

  int _clampDay(int day, int year, int month) {
    final maxDay = DateTime(year, month + 1, 0).day;
    if (day < 1) return 1;
    if (day > maxDay) return maxDay;
    return day;
  }

  String _dateOnly(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  Future<StatementsAnalyticsTotals> _fetchRangeTotals({
    required String dateFrom,
    required String dateTo,
  }) async {
    final batchId = selectedBatchId!;
    if (batchId == 'all') {
      var totalIncome = 0.0;
      var totalExpense = 0.0;
      var totalNet = 0.0;
      var totalCount = 0;
      for (final batch in batches) {
        final id =
            (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString();
        if (id == null || id.isEmpty) continue;
        final res = await _api.analyticsSummary(
          batchId: id,
          dateFrom: dateFrom,
          dateTo: dateTo,
        );
        final totals = _totalsFromSummary(res);
        totalIncome += totals.income;
        totalExpense += totals.expense;
        totalNet += totals.net;
        totalCount += totals.count;
      }
      return StatementsAnalyticsTotals(
        income: totalIncome,
        expense: totalExpense,
        net: totalNet,
        count: totalCount,
      );
    }
    final res = await _api.analyticsSummary(
      batchId: batchId,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
    return _totalsFromSummary(res);
  }

  StatementsAnalyticsTotals _totalsFromSummary(Map<String, dynamic> res) {
    final monthsList = (res['months'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    var income = 0.0;
    var expense = 0.0;
    var net = 0.0;
    var count = 0;
    for (final row in monthsList) {
      income += (row['income'] as num?)?.toDouble() ?? 0;
      expense += (row['expense'] as num?)?.toDouble() ?? 0;
      net += (row['net'] as num?)?.toDouble() ?? 0;
      count += (row['count'] as num?)?.toInt() ?? 0;
    }
    return StatementsAnalyticsTotals(
      income: income,
      expense: expense,
      net: net,
      count: count,
    );
  }
}

class StatementsAnalyticsTotals {
  StatementsAnalyticsTotals({
    required this.income,
    required this.expense,
    required this.net,
    required this.count,
  });

  final num income;
  final num expense;
  final num net;
  final int count;
}

class StatementsAnalyticsCompareRow {
  StatementsAnalyticsCompareRow({
    required this.year,
    required this.month,
    required this.calendarStart,
    required this.calendarEnd,
    required this.settlementStart,
    required this.settlementEnd,
    required this.calendarTotals,
    required this.settlementTotals,
  });

  final int year;
  final int month;
  final DateTime calendarStart;
  final DateTime calendarEnd;
  final DateTime settlementStart;
  final DateTime settlementEnd;
  final StatementsAnalyticsTotals calendarTotals;
  final StatementsAnalyticsTotals settlementTotals;

  StatementsAnalyticsTotals get delta => StatementsAnalyticsTotals(
        income: settlementTotals.income - calendarTotals.income,
        expense: settlementTotals.expense - calendarTotals.expense,
        net: settlementTotals.net - calendarTotals.net,
        count: settlementTotals.count - calendarTotals.count,
      );
}

class _AggRow {
  _AggRow({this.year, this.month, this.merchant});

  final String? year;
  final String? month;
  final String? merchant;

  num expense = 0;
  num income = 0;
  num net = 0;
  int count = 0;
  num total = 0;

  void add(Map<String, dynamic> row, {bool isMerchant = false}) {
    if (isMerchant) {
      total += (row['total'] as num?) ?? 0;
      count += (row['count'] as int?) ?? 0;
      return;
    }
    expense += (row['expense'] as num?) ?? 0;
    income += (row['income'] as num?) ?? 0;
    net = income - expense;
    count += (row['count'] as int?) ?? 0;
  }

  Map<String, dynamic> toYearMap(int yearKey) => {
        'year': yearKey,
        'expense': expense,
        'income': income,
        'net': net,
        'count': count,
      };

  Map<String, dynamic> toMonthMap() => {
        'year': year,
        'month': month,
        'expense': expense,
        'income': income,
        'net': net,
        'count': count,
      };

  Map<String, dynamic> toMerchantMap() => {
        'merchant': merchant ?? '-',
        'total': total,
        'count': count,
      };
}
