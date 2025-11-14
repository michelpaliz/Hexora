import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/i_time_tracking_api_client.dart';

//Public app level abstraction
abstract class ITimeTrackingRepository {
  Future<void> enable(String groupId, String token);
  Future<void> disable(String groupId, String token);

  Future<List<Worker>> getWorkers(String groupId, String token);
  Future<Worker> addWorker(String groupId, Worker worker, String token);

  Future<List<TimeEntry>> getTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });

  Future<TimeEntry> createTimeEntry(
    String groupId,
    TimeEntry entry,
    String token,
  );

  Future<Uint8List> exportExcel(String groupId, String token);

  Future<Map<String, dynamic>> getWorkerTotals(
    String groupId,
    String token, {
    String? workerId,
    DateTime? from,
    DateTime? to,
  });
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token,
  );

  Future<TimeEntry> updateTimeEntry(
    String groupId,
    String entryId,
    TimeEntry entry,
    String token,
  );

  Future<void> deleteTimeEntry(
    String groupId,
    String entryId,
    String token,
  );

  Future<int> purgeTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });

  /// Export to Excel with optional filters (?from, ?to, ?workerId)
  Future<Uint8List> exportExcelFiltered(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });
}

class TimeTrackingRepository implements ITimeTrackingRepository {
  final ITimeTrackingApiClient _api;
  TimeTrackingRepository(this._api);

  @override
  Future<void> enable(String groupId, String token) =>
      _api.enable(groupId, token);

  @override
  Future<void> disable(String groupId, String token) =>
      _api.disable(groupId, token);

  @override
  Future<List<Worker>> getWorkers(String groupId, String token) =>
      _api.listWorkers(groupId, token);

  @override
  Future<Worker> addWorker(String groupId, Worker worker, String token) =>
      _api.createWorker(groupId, worker, token);

  @override
  Future<List<TimeEntry>> getTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) =>
      _api.listTimeEntries(
        groupId,
        token,
        from: from,
        to: to,
        workerId: workerId,
      );

  @override
  Future<TimeEntry> createTimeEntry(
    String groupId,
    TimeEntry entry,
    String token,
  ) =>
      _api.createTimeEntry(groupId, entry, token);

  @override
  Future<Uint8List> exportExcel(String groupId, String token) =>
      _api.exportExcel(groupId, token);

  @override
  Future<Map<String, dynamic>> getWorkerTotals(
    String groupId,
    String token, {
    String? workerId,
    DateTime? from,
    DateTime? to,
  }) =>
      _api.getWorkerTotals(
        groupId,
        token,
        workerId: workerId,
        from: from,
        to: to,
      );

  @override
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token,
  ) =>
      _api.updateWorker(groupId, workerId, worker, token);

  @override
  Future<TimeEntry> updateTimeEntry(
    String groupId,
    String entryId,
    TimeEntry entry,
    String token,
  ) =>
      _api.updateTimeEntry(groupId, entryId, entry, token);

  @override
  Future<void> deleteTimeEntry(
    String groupId,
    String entryId,
    String token,
  ) =>
      _api.deleteTimeEntry(groupId, entryId, token);

  @override
  Future<int> purgeTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) =>
      _api.purgeTimeEntries(
        groupId,
        token,
        from: from,
        to: to,
        workerId: workerId,
      );

  @override
  Future<Uint8List> exportExcelFiltered(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) {
    // If your API client already supports range params, call that.
    // Otherwise build here (shown using _api.listTimeEntries pattern):

    // We’ll reuse the API client’s export endpoint if you’ve added params there.
    // Assuming you extend your API client with the same signature.
    // If not yet extended, you can temporarily call exportExcel(groupId, token)
    // and the server will default to current month.
    return _api.exportExcelFiltered(
      groupId,
      token,
      from: from,
      to: to,
      workerId: workerId,
    );
  }
}
