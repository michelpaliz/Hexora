import 'dart:async';

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
  StatementsAnalyticsController({
    StatementsApi? api,
    String? groupId,
  })  : _api = api ?? StatementsApi(),
        _groupId = groupId;

  final StatementsApi _api;
  final String? _groupId;
  bool _isDisposed = false;
  int _entriesRequestId = 0;
  int _statusRequestId = 0;

  bool loadingBatches = false;
  String? batchesError;
  List<Map<String, dynamic>> batches = const [];

  bool loadingSummary = false;
  String? summaryError;
  Map<String, dynamic> summary = const {};
  List<Map<String, dynamic>> settlementYearRows = const [];

  bool loadingEntries = false;
  String? entriesError;
  List<Map<String, dynamic>> entries = const [];

  bool loadingStatus = false;
  String? statusError;
  StatementsAnalyticsStatusSnapshot? statusSnapshot;

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
      (periodMode == StatementsAnalyticsPeriodMode.settlementWindow &&
              selectedYear == null &&
              settlementYearRows.isNotEmpty)
          ? settlementYearRows
          : (summary['years'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

  List<Map<String, dynamic>> get months => (summary['months'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  List<Map<String, dynamic>> get topExpense => ((summary['topMerchants'] is Map
              ? (summary['topMerchants'] as Map)['expense']
              : null) as List? ??
          const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  List<Map<String, dynamic>> get topIncome => ((summary['topMerchants'] is Map
              ? (summary['topMerchants'] as Map)['income']
              : null) as List? ??
          const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  List<Map<String, dynamic>> get trendRows {
    final useSettlement =
        periodMode == StatementsAnalyticsPeriodMode.settlementWindow &&
            selectedYear != null &&
            compareRows.isNotEmpty;
    if (useSettlement) {
      return compareRows
          .map(
            (row) => {
              'year': row.year,
              'month': row.month,
              'income': row.settlementTotals.income,
              'expense': row.settlementTotals.expense,
              'net': row.settlementTotals.net,
              'count': row.settlementTotals.count,
            },
          )
          .toList(growable: false);
    }
    return selectedYear == null ? years : months;
  }

  List<Map<String, dynamic>> get averageTrendRows {
    return trendRows.map((row) {
      final count = (row['count'] as num?)?.toDouble() ?? 0;
      final divisor = count == 0 ? 1.0 : count;
      return {
        ...row,
        'income': ((row['income'] as num?)?.toDouble() ?? 0) / divisor,
        'expense': ((row['expense'] as num?)?.toDouble() ?? 0) / divisor,
        'net': ((row['net'] as num?)?.toDouble() ?? 0) / divisor,
      };
    }).toList(growable: false);
  }

  StatementsAnalyticsTotals get visibleTotals => _totalsFromRows(trendRows);

  StatementsAnalyticsTicketStats? get ticketStats {
    if (entries.isEmpty) return null;
    var incomeSum = 0.0;
    var expenseSum = 0.0;
    var incomeCount = 0;
    var expenseCount = 0;
    var largestIncome = 0.0;
    var largestExpense = 0.0;
    for (final row in entries) {
      final amount = _entryAmount(row);
      if (amount == null || amount == 0) continue;
      if (amount > 0) {
        incomeSum += amount;
        incomeCount += 1;
        if (amount > largestIncome) largestIncome = amount;
      } else {
        final absolute = amount.abs();
        expenseSum += absolute;
        expenseCount += 1;
        if (absolute > largestExpense) largestExpense = absolute;
      }
    }
    return StatementsAnalyticsTicketStats(
      averageIncome: incomeCount == 0 ? 0 : incomeSum / incomeCount,
      averageExpense: expenseCount == 0 ? 0 : expenseSum / expenseCount,
      largestIncome: largestIncome,
      largestExpense: largestExpense,
      transactionCount: entries.length,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
    );
  }

  StatementsAnalyticsLinkStats? get linkStats {
    if (entries.isEmpty) return null;
    var linkedCount = 0;
    var unlinkedCount = 0;
    for (final row in entries) {
      if (_isLinked(row)) {
        linkedCount += 1;
      } else {
        unlinkedCount += 1;
      }
    }
    return StatementsAnalyticsLinkStats(
      linkedCount: linkedCount,
      unlinkedCount: unlinkedCount,
    );
  }

  bool get volumeUsesDaily =>
      entries.isNotEmpty && _selectedDateRangeDays <= 45 && _selectedDateRangeDays > 0;

  List<StatementsAnalyticsVolumePoint> get volumePoints {
    if (volumeUsesDaily) {
      final grouped = <DateTime, _DateBucket>{};
      for (final row in entries) {
        final date = _entryDate(row);
        if (date == null) continue;
        final key = DateTime(date.year, date.month, date.day);
        final bucket = grouped.putIfAbsent(key, _DateBucket.new);
        bucket.count += 1;
        bucket.absoluteMovement += (_entryAmount(row) ?? 0).abs();
      }
      final dates = grouped.keys.toList()..sort();
      return dates
          .map(
            (date) => StatementsAnalyticsVolumePoint(
              date: date,
              label: '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}',
              count: grouped[date]!.count,
              absoluteMovement: grouped[date]!.absoluteMovement,
              daily: true,
            ),
          )
          .toList(growable: false);
    }

    return trendRows.map((row) {
      final year = int.tryParse(row['year']?.toString() ?? '');
      final month = int.tryParse(row['month']?.toString() ?? '');
      final label = month == null
          ? (year?.toString() ?? '-')
          : month.toString().padLeft(2, '0');
      final income = (row['income'] as num?)?.toDouble() ?? 0;
      final expense = (row['expense'] as num?)?.toDouble() ?? 0;
      return StatementsAnalyticsVolumePoint(
        date: (year != null && month != null) ? DateTime(year, month) : null,
        label: label,
        count: (row['count'] as num?)?.toInt() ?? 0,
        absoluteMovement: income + expense,
        daily: false,
      );
    }).toList(growable: false);
  }

  List<StatementsAnalyticsHeatmapDay> get heatmapDays {
    if (entries.isEmpty) return const [];
    final grouped = <DateTime, _DateBucket>{};
    for (final row in entries) {
      final date = _entryDate(row);
      if (date == null) continue;
      final key = DateTime(date.year, date.month, date.day);
      final bucket = grouped.putIfAbsent(key, _DateBucket.new);
      bucket.count += 1;
      bucket.absoluteMovement += (_entryAmount(row) ?? 0).abs();
    }
    if (grouped.isEmpty) return const [];

    final allDates = grouped.keys.toList()..sort();
    var start = allDates.first;
    var end = allDates.last;
    final fixedRange = _selectedHeatmapRange();
    if (fixedRange != null) {
      start = fixedRange.start;
      end = fixedRange.end;
    } else {
      final span = end.difference(start).inDays + 1;
      if (span > 84) {
        start = end.subtract(const Duration(days: 83));
      }
    }

    final days = <StatementsAnalyticsHeatmapDay>[];
    for (var cursor = start;
        !cursor.isAfter(end);
        cursor = cursor.add(const Duration(days: 1))) {
      final bucket = grouped[DateTime(cursor.year, cursor.month, cursor.day)];
      days.add(
        StatementsAnalyticsHeatmapDay(
          date: cursor,
          count: bucket?.count ?? 0,
          absoluteMovement: bucket?.absoluteMovement ?? 0,
        ),
      );
    }
    return days;
  }

  Future<void> loadBatches() async {
    if (loadingBatches) return;
    loadingBatches = true;
    batchesError = null;
    _notify();
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
      _notify();
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
    _notify();
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
    _primeDerivedLoading();
    _notify();
    try {
      settlementYearRows = const [];
      final settlementRange = _settlementRange();
      final dateFrom =
          settlementRange == null ? null : _dateOnly(settlementRange.start);
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
      if (periodMode == StatementsAnalyticsPeriodMode.settlementWindow &&
          selectedYear == null) {
        final years = (summary['years'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => int.tryParse(e['year']?.toString() ?? ''))
            .whereType<int>()
            .toList()
          ..sort();
        if (years.isNotEmpty) {
          settlementYearRows = await _buildSettlementYearRows(years);
        }
      }
      loadingSummary = false;
      _notify();
      final entriesRequestId = ++_entriesRequestId;
      final statusRequestId = ++_statusRequestId;
      unawaited(_fetchEntries(entriesRequestId));
      unawaited(_fetchStatus(statusRequestId));
    } catch (e) {
      summaryError = e.toString();
      loadingEntries = false;
      loadingStatus = false;
      entries = const [];
      statusSnapshot = null;
      statusError = null;
    } finally {
      loadingSummary = false;
      _notify();
    }
  }

  Future<void> fetchComparison() async {
    if (selectedBatchId == null || selectedYear == null) {
      compareRows = const [];
      compareError = null;
      _notify();
      return;
    }
    if (loadingCompare) return;
    loadingCompare = true;
    compareError = null;
    _notify();
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
      _notify();
    }
  }

  Future<void> _fetchEntries(int requestId) async {
    loadingEntries = true;
    entriesError = null;
    if (requestId == _entriesRequestId) {
      entries = const [];
    }
    _notify();
    try {
      final query = _buildEntriesQuery();
      final fetched = selectedBatchId == 'all'
          ? await _fetchAllEntries(query)
          : await _fetchBatchEntriesByPage(selectedBatchId!, query);
      if (requestId != _entriesRequestId) return;
      entries = fetched;
    } catch (e) {
      if (requestId != _entriesRequestId) return;
      entriesError = e.toString();
      entries = const [];
    } finally {
      if (requestId == _entriesRequestId) {
        loadingEntries = false;
        _notify();
      }
    }
  }

  Future<void> _fetchStatus(int requestId) async {
    loadingStatus = true;
    statusError = null;
    if (requestId == _statusRequestId) {
      statusSnapshot = null;
    }
    _notify();
    try {
      final snapshot = selectedBatchId == 'all'
          ? await _fetchAggregatedStatus()
          : await _fetchSingleStatus(selectedBatchId!);
      if (requestId != _statusRequestId) return;
      statusSnapshot = snapshot;
    } catch (e) {
      if (requestId != _statusRequestId) return;
      statusError = e.toString();
      statusSnapshot = null;
    } finally {
      if (requestId == _statusRequestId) {
        loadingStatus = false;
        _notify();
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllEntries(
    _StatementsEntriesQuery query,
  ) async {
    final groupId = _resolveGroupId();
    if (groupId != null) {
      return _fetchGroupEntries(groupId, query);
    }
    final items = <Map<String, dynamic>>[];
    for (final batch in batches) {
      final batchId =
          (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString();
      if (batchId == null || batchId.isEmpty) continue;
      items.addAll(await _fetchBatchEntriesByPage(batchId, query));
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> _fetchGroupEntries(
    String groupId,
    _StatementsEntriesQuery query,
  ) async {
    const size = 200;
    final items = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final res = await _api.fetchStatementEntries(
        groupId: groupId,
        page: page,
        size: size,
        year: query.year,
        dateFrom: query.dateFrom,
        dateTo: query.dateTo,
      );
      items.addAll(
        res.items.map((entry) => Map<String, dynamic>.from(entry.raw)),
      );
      if (page >= res.totalPages || res.items.isEmpty) {
        break;
      }
      page += 1;
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> _fetchBatchEntriesByPage(
    String batchId,
    _StatementsEntriesQuery query,
  ) async {
    const size = 200;
    final items = <Map<String, dynamic>>[];
    var page = 1;
    while (true) {
      final res = await _api.batchEntriesPaged(
        batchId: batchId,
        page: page,
        size: size,
        year: query.year,
        dateFrom: query.dateFrom == null ? null : _dateOnly(query.dateFrom!),
        dateTo: query.dateTo == null ? null : _dateOnly(query.dateTo!),
        order: 'date_desc',
      );
      final pageItems = _pageItems(res);
      items.addAll(pageItems);
      final totalPages = (res['totalPages'] as num?)?.toInt() ?? 1;
      if (page >= totalPages || pageItems.isEmpty || pageItems.length < size) {
        break;
      }
      page += 1;
    }
    return items;
  }

  Future<StatementsAnalyticsStatusSnapshot> _fetchSingleStatus(
    String batchId,
  ) async {
    final raw = await _api.batchStatus(batchId: batchId);
    final lastDate = _tryParseDate(raw['lastDate']);
    return StatementsAnalyticsStatusSnapshot(
      lastDate: lastDate,
      daysSince: (raw['daysSince'] as num?)?.toInt(),
      thresholdDays: (raw['thresholdDays'] as num?)?.toInt(),
      stale: raw['stale'] == true,
      totalBatches: 1,
      staleBatches: raw['stale'] == true ? 1 : 0,
      freshBatches: raw['stale'] == true ? 0 : 1,
    );
  }

  Future<StatementsAnalyticsStatusSnapshot> _fetchAggregatedStatus() async {
    final valid = <Map<String, dynamic>>[];
    for (final batch in batches) {
      final batchId =
          (batch['batchId'] ?? batch['_id'] ?? batch['id'])?.toString();
      if (batchId == null || batchId.isEmpty) continue;
      try {
        valid.add(await _api.batchStatus(batchId: batchId));
      } catch (_) {}
    }
    if (valid.isEmpty) {
      throw Exception('No freshness status available');
    }
    DateTime? latest;
    int? thresholdDays;
    var staleBatches = 0;
    var freshBatches = 0;
    for (final row in valid) {
      final stale = row['stale'] == true;
      if (stale) {
        staleBatches += 1;
      } else {
        freshBatches += 1;
      }
      thresholdDays ??= (row['thresholdDays'] as num?)?.toInt();
      final date = _tryParseDate(row['lastDate']);
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
    final daysSince = latest == null
        ? null
        : DateTime.now().difference(DateTime(
            latest.year,
            latest.month,
            latest.day,
          )).inDays;
    return StatementsAnalyticsStatusSnapshot(
      lastDate: latest,
      daysSince: daysSince,
      thresholdDays: thresholdDays,
      stale: freshBatches == 0,
      totalBatches: valid.length,
      staleBatches: staleBatches,
      freshBatches: freshBatches,
    );
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
        years.putIfAbsent(year, _AggRow.new);
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
          expenseMerchants.putIfAbsent(
            merchant,
            () => _AggRow(merchant: merchant),
          );
          expenseMerchants[merchant]!.add(row, isMerchant: true);
        }
        final incomeList = (topMerchants['income'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (final row in incomeList) {
          final merchant = row['merchant']?.toString() ?? '';
          if (merchant.isEmpty) continue;
          incomeMerchants.putIfAbsent(
            merchant,
            () => _AggRow(merchant: merchant),
          );
          incomeMerchants[merchant]!.add(row, isMerchant: true);
        }
      }
    }

    final yearsOut = years.entries.map((e) => e.value.toYearMap(e.key)).toList()
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
    final topExpense = expenseMerchants.values.map((e) => e.toMerchantMap()).toList()
      ..sort((a, b) => (b['total'] as num).compareTo(a['total'] as num));
    final topIncome = incomeMerchants.values.map((e) => e.toMerchantMap()).toList()
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
    final end = DateTime(year, month + 1, 0);
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

  String _dateOnly(DateTime dt) => '${dt.year.toString().padLeft(4, '0')}-'
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
    return _totalsFromRows(monthsList);
  }

  StatementsAnalyticsTotals _totalsFromRows(List<Map<String, dynamic>> rows) {
    var income = 0.0;
    var expense = 0.0;
    var net = 0.0;
    var count = 0;
    for (final row in rows) {
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

  Future<List<Map<String, dynamic>>> _buildSettlementYearRows(
    List<int> years,
  ) async {
    final rows = <Map<String, dynamic>>[];
    for (final year in years) {
      num income = 0;
      num expense = 0;
      num net = 0;
      int count = 0;
      for (var month = 1; month <= 12; month += 1) {
        final range = _settlementWindowRange(year, month);
        final totals = await _fetchRangeTotals(
          dateFrom: _dateOnly(range.start),
          dateTo: _dateOnly(range.end),
        );
        income += totals.income;
        expense += totals.expense;
        net += totals.net;
        count += totals.count;
      }
      rows.add({
        'year': year,
        'income': income,
        'expense': expense,
        'net': net,
        'count': count,
      });
    }
    rows.sort((a, b) => (a['year'] as int).compareTo((b['year'] as int)));
    return rows;
  }

  _StatementsEntriesQuery _buildEntriesQuery() {
    final settlement = _settlementRange();
    if (settlement != null) {
      return _StatementsEntriesQuery(
        dateFrom: settlement.start,
        dateTo: _endOfDay(settlement.end),
      );
    }
    if (selectedYear != null && selectedMonth != null) {
      final range = _calendarRange(selectedYear!, selectedMonth!);
      return _StatementsEntriesQuery(
        dateFrom: range.start,
        dateTo: _endOfDay(range.end),
      );
    }
    if (selectedYear != null) {
      return _StatementsEntriesQuery(year: selectedYear);
    }
    return const _StatementsEntriesQuery();
  }

  ({DateTime start, DateTime end})? _selectedHeatmapRange() {
    final settlement = _settlementRange();
    if (settlement != null) {
      return (
        start: DateTime(
          settlement.start.year,
          settlement.start.month,
          settlement.start.day,
        ),
        end: DateTime(
          settlement.end.year,
          settlement.end.month,
          settlement.end.day,
        ),
      );
    }
    if (selectedYear != null && selectedMonth != null) {
      return _calendarRange(selectedYear!, selectedMonth!);
    }
    return null;
  }

  int get _selectedDateRangeDays {
    final range = _selectedHeatmapRange();
    if (range == null) return 0;
    return range.end.difference(range.start).inDays + 1;
  }

  void _primeDerivedLoading() {
    loadingEntries = true;
    entriesError = null;
    entries = const [];
    loadingStatus = true;
    statusError = null;
    statusSnapshot = null;
  }

  String? _resolveGroupId() {
    final direct = _groupId?.trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final batch in batches) {
      final candidate = batch['groupId']?.toString().trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _pageItems(Map<String, dynamic> page) {
    final rawEntries = page['entries'];
    if (rawEntries is List) {
      return rawEntries
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    final rawItems = page['items'];
    if (rawItems is List) {
      return rawItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  DateTime _endOfDay(DateTime value) => DateTime(
        value.year,
        value.month,
        value.day,
        23,
        59,
        59,
        999,
      );

  DateTime? _entryDate(Map<String, dynamic> row) {
    return _tryParseDate(row['date']) ?? _tryParseDate(row['valueDate']);
  }

  DateTime? _tryParseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    return parsed?.toLocal();
  }

  double? _entryAmount(Map<String, dynamic> row) {
    final raw = row['amount'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(',', '.'));
  }

  bool _isLinked(Map<String, dynamic> row) {
    final invoiceIds = row['invoiceIds'];
    return _hasValue(row['clientId']) ||
        _hasValue(row['invoiceId']) ||
        (invoiceIds is List && invoiceIds.isNotEmpty) ||
        _hasValue(row['expenseDocumentId']);
  }

  bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    return true;
  }

  void _notify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
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

class StatementsAnalyticsVolumePoint {
  const StatementsAnalyticsVolumePoint({
    required this.date,
    required this.label,
    required this.count,
    required this.absoluteMovement,
    required this.daily,
  });

  final DateTime? date;
  final String label;
  final int count;
  final num absoluteMovement;
  final bool daily;
}

class StatementsAnalyticsTicketStats {
  const StatementsAnalyticsTicketStats({
    required this.averageIncome,
    required this.averageExpense,
    required this.largestIncome,
    required this.largestExpense,
    required this.transactionCount,
    required this.incomeCount,
    required this.expenseCount,
  });

  final double averageIncome;
  final double averageExpense;
  final double largestIncome;
  final double largestExpense;
  final int transactionCount;
  final int incomeCount;
  final int expenseCount;
}

class StatementsAnalyticsLinkStats {
  const StatementsAnalyticsLinkStats({
    required this.linkedCount,
    required this.unlinkedCount,
  });

  final int linkedCount;
  final int unlinkedCount;

  int get total => linkedCount + unlinkedCount;

  double get linkedRatio => total == 0 ? 0 : linkedCount / total;
}

class StatementsAnalyticsHeatmapDay {
  const StatementsAnalyticsHeatmapDay({
    required this.date,
    required this.count,
    required this.absoluteMovement,
  });

  final DateTime date;
  final int count;
  final num absoluteMovement;
}

class StatementsAnalyticsStatusSnapshot {
  const StatementsAnalyticsStatusSnapshot({
    required this.lastDate,
    required this.daysSince,
    required this.thresholdDays,
    required this.stale,
    required this.totalBatches,
    required this.staleBatches,
    required this.freshBatches,
  });

  final DateTime? lastDate;
  final int? daysSince;
  final int? thresholdDays;
  final bool stale;
  final int totalBatches;
  final int staleBatches;
  final int freshBatches;

  bool get mixed => staleBatches > 0 && freshBatches > 0;
}

class _StatementsEntriesQuery {
  const _StatementsEntriesQuery({
    this.year,
    this.dateFrom,
    this.dateTo,
  });

  final int? year;
  final DateTime? dateFrom;
  final DateTime? dateTo;
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

class _DateBucket {
  int count = 0;
  num absoluteMovement = 0;
}
