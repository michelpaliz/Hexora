import 'package:flutter/foundation.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/auth_user/user/domain/user_domain.dart';
import 'package:hexora/b-backend/business_logic/worker/repository/time_tracking_repository.dart';

class WorkerTimeTrackingController extends ChangeNotifier {
  WorkerTimeTrackingController({
    required this.group,
    required this.worker,
    required ITimeTrackingRepository repo,
    required UserDomain userDomain,
    int? initialYear,
    int? initialMonth,
  })  : _repo = repo,
        _userDomain = userDomain {
    final now = DateTime.now();
    _year = initialYear ?? now.year;
    _month = initialMonth ?? now.month;
  }

  final Group group;
  final Worker worker;
  final ITimeTrackingRepository _repo;
  final UserDomain _userDomain;

  bool loading = false;
  bool error = false;
  List<TimeEntry> entries = [];
  Map<String, dynamic>? totals;

  late int _year;
  late int _month;

  int get year => _year;
  int get month => _month;
  DateTime get _fromUtc => DateTime(_year, _month, 1).toUtc();
  DateTime get _toUtc =>
      (_month < 12 ? DateTime(_year, _month + 1, 1) : DateTime(_year + 1, 1, 1))
          .toUtc();

  Future<String> _token() => _userDomain.getAuthToken();

  Future<void> load() async {
    loading = true;
    error = false;
    notifyListeners();

    try {
      final token = await _token();

      final fetched = await _repo.getTimeEntries(
        group.id,
        token,
        workerId: worker.id,
        from: _fromUtc,
        to: _toUtc,
      );

      Map<String, dynamic> t;
      try {
        t = await _repo.getWorkerTotals(
          group.id,
          token,
          workerId: worker.id,
          from: _fromUtc,
          to: _toUtc,
        );
      } catch (_) {
        t = {'totalHours': '0.00', 'totalPay': '0.00', 'currency': ''};
      }

      entries = fetched;
      totals = t;
      loading = false;
      notifyListeners();
    } catch (_) {
      error = true;
      loading = false;
      notifyListeners();
    }
  }

  // If you ever re-enable month nav (arrows), call these then load()
  void setMonth(int year, int month) {
    _year = year;
    _month = month;
    notifyListeners();
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
}
