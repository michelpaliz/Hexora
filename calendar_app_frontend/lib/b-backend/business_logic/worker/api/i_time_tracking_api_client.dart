import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';

//Defines raw HTTP endpoints
abstract class ITimeTrackingApiClient {
  /// POST /groups/:groupId/time-tracking/enable
  Future<void> enable(String groupId, String token);

  /// POST /groups/:groupId/time-tracking/disable
  Future<void> disable(String groupId, String token);

  /// GET /groups/:groupId/time-tracking/workers
  /// Implementation should return [] if 404 (no workers / not provisioned yet).
  Future<List<Worker>> listWorkers(String groupId, String token);

  /// POST /groups/:groupId/time-tracking/workers
  Future<Worker> createWorker(String groupId, Worker worker, String token);

  /// GET /groups/:groupId/time-tracking/time-entries
  /// Optional filters via query params (?from, ?to, ?workerId).
  /// Implementation may return [] on 404.
  Future<List<TimeEntry>> listTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });

  /// POST /groups/:groupId/time-tracking/time-entries
  Future<TimeEntry> createTimeEntry(
    String groupId,
    TimeEntry entry,
    String token,
  );

  /// GET /groups/:groupId/time-tracking/export
  Future<Uint8List> exportExcel(String groupId, String token);

  /// GET /groups/:groupId/time-tracking/totals
  /// Optional filters via query params (?from, ?to, ?workerId)
  /// Returns total hours and pay for a worker.
  Future<Map<String, dynamic>> getWorkerTotals(
    String groupId,
    String token, {
    String? workerId,
    DateTime? from,
    DateTime? to,
  });

  /// PUT /groups/:groupId/time-tracking/workers/:workerId
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token,
  );

  /// PUT /groups/:groupId/time-tracking/time-entries/:entryId
  Future<TimeEntry> updateTimeEntry(
    String groupId,
    String entryId,
    TimeEntry entry,
    String token,
  );

  /// DELETE /groups/:groupId/time-tracking/time-entries/:entryId
  Future<void> deleteTimeEntry(
    String groupId,
    String entryId,
    String token,
  );

  /// DELETE /groups/:groupId/time-tracking/time-entries?from&to&workerId
  /// Returns number of deleted entries.
  Future<int> purgeTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });

    /// GET /groups/:groupId/time-tracking/export?from&to&workerId
  Future<Uint8List> exportExcelFiltered(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  });
}

