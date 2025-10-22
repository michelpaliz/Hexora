import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/business_logic/worker/api/i_time_tracking_api_client.dart';

abstract class ITimeTrackingRepository {
  Future<void> enable(String groupId, String token);
  Future<void> disable(String groupId, String token);

  Future<List<Worker>> getWorkers(String groupId, String token);
  Future<Worker> addWorker(String groupId, Worker worker, String token);

  // ... your TimeEntry methods unchanged ...
  Future<Uint8List> exportExcel(String groupId, String token);
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
  Future<Uint8List> exportExcel(String groupId, String token) =>
      _api.exportExcel(groupId, token);
}
