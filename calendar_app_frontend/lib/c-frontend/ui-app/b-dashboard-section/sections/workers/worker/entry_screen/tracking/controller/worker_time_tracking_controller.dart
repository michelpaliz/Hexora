import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';

class WorkerTimeTrackingController extends ChangeNotifier {
  WorkerTimeTrackingController({
    required this.group,
    required Worker worker,
    required ITimeTrackingRepository repo,
    required UserDomain userDomain,
    int? initialYear,
    int? initialMonth,
  })  : _repo = repo,
        _userDomain = userDomain,
        _worker = worker {
    final now = DateTime.now();
    _year = initialYear ?? now.year;
    _month = initialMonth ?? now.month;
  }

  final Group group;
  Worker _worker;
  final ITimeTrackingRepository _repo;
  final UserDomain _userDomain;
  bool _isDisposed = false;

  bool loading = false;
  bool error = false;
  bool totalsLoading = false;
  String? totalsError;
  List<TimeEntry> entries = [];
  Map<String, dynamic>? totals;
  double? _advanceAmountOverride;

  late int _year;
  late int _month;

  Worker get worker => _worker;
  int get year => _year;
  int get month => _month;
  double get advanceAmount {
    if (_advanceAmountOverride != null) return _advanceAmountOverride!;
    final raw = totals?['advanceAmount'];
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed != null) return parsed;
    return _worker.advanceAmount ?? 0;
  }

  double? get advanceAmountOverride => _advanceAmountOverride;
  String get _monthValue => '$_year-${_month.toString().padLeft(2, '0')}';
  DateTime get _fromUtc => DateTime(_year, _month, 1).toUtc();
  DateTime get _toUtc =>
      (_month < 12 ? DateTime(_year, _month + 1, 1) : DateTime(_year + 1, 1, 1))
          .toUtc();

  Future<String> _token() => _userDomain.getAuthToken();

  void _notifySafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  Future<void> _refreshWorkerForMonth(String token) async {
    final workers = await _repo.getWorkers(
      group.id,
      token,
      month: _monthValue,
    );
    final matched = workers.where((item) => item.id == _worker.id);
    if (matched.isNotEmpty) {
      _worker = matched.first;
    }
  }

  Future<void> load() async {
    if (_isDisposed) return;
    loading = true;
    error = false;
    totalsError = null;
    _notifySafely();

    try {
      final token = await _token();
      if (_isDisposed) return;

      final fetched = await _repo.getTimeEntries(
        group.id,
        token,
        workerId: worker.id,
        from: _fromUtc,
        to: _toUtc,
      );
      if (_isDisposed) return;

      await _refreshWorkerForMonth(token);
      if (_isDisposed) return;

      Map<String, dynamic> t;
      try {
        t = await _repo.getWorkerTotals(
          group.id,
          token,
          workerId: worker.id,
          month: _monthValue,
          from: _fromUtc,
          to: _toUtc,
          advanceAmount: _advanceAmountOverride,
        );
        if (_isDisposed) return;
      } catch (_) {
        t = {
          'totalHours': '0.00',
          'totalPay': '0.00',
          'grossPay': '0.00',
          'advanceAmount': (_advanceAmountOverride ?? 0).toStringAsFixed(2),
          'netPay': '0.00',
          'currency': ''
        };
      }

      entries = fetched;
      totals = t;
      loading = false;
      _notifySafely();
    } catch (_) {
      if (_isDisposed) return;
      error = true;
      loading = false;
      _notifySafely();
    }
  }

  Future<void> saveAdvanceAmount(double value) async {
    if (value < 0) return;
    _advanceAmountOverride = value;
    final token = await _token();
    final updatedWorker = _worker.copyWith(advanceAmount: value);
    _worker = await _repo.updateWorker(
      group.id,
      _worker.id,
      updatedWorker,
      token,
      month: _monthValue,
    );
    await refreshTotals();
  }

  Future<void> refreshTotals() async {
    if (_isDisposed) return;
    totalsLoading = true;
    totalsError = null;
    _notifySafely();
    try {
      final token = await _token();
      if (_isDisposed) return;
      totals = await _repo.getWorkerTotals(
        group.id,
        token,
        workerId: worker.id,
        month: _monthValue,
        from: _fromUtc,
        to: _toUtc,
        advanceAmount: _advanceAmountOverride,
      );
      if (_isDisposed) return;
    } catch (e) {
      if (_isDisposed) return;
      totalsError = e.toString();
    } finally {
      if (!_isDisposed) {
        totalsLoading = false;
        _notifySafely();
      }
    }
  }

  // If you ever re-enable month nav (arrows), call these then load()
  void setMonth(int year, int month) {
    if (_isDisposed) return;
    _year = year;
    _month = month;
    _notifySafely();
  }

  Future<Uint8List> exportExcelFiltered() async {
    final token = await _token();
    return _repo.exportExcelFiltered(
      group.id,
      token,
      from: _fromUtc,
      to: _toUtc,
      workerId: worker.id,
    );
  }

  Future<Uint8List> previewPayrollPdf({required String lang}) async {
    final token = await _token();
    return _repo.previewPayrollPdf(
      group.id,
      token,
      from: _fromUtc,
      to: _toUtc,
      workerId: worker.id,
      lang: lang,
      advanceAmount: _advanceAmountOverride,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
