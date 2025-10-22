import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:meta/meta.dart';

@immutable
class TimeEntry {/* keep your TimeEntry for now, unchanged */}

abstract class ITimeTrackingApiClient {
  Future<void> enable(String groupId, String token);
  Future<void> disable(String groupId, String token);

  Future<List<Worker>> listWorkers(String groupId, String token);
  Future<Worker> createWorker(String groupId, Worker worker, String token);

  Future<List<TimeEntry>> listTimeEntries(
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
}
