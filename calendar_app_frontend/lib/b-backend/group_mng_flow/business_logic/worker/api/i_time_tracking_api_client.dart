import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/working_time_excel_import.dart';
import 'package:hexora/a-models/group_model/worker/working_time_history.dart';
import 'package:hexora/a-models/group_model/worker/working_time_import_instructions.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';

//Defines raw HTTP endpoints
abstract class ITimeTrackingApiClient {
  /// POST /groups/:groupId/time-tracking/enable
  Future<void> enable(String groupId, String token);

  /// POST /groups/:groupId/time-tracking/disable
  Future<void> disable(String groupId, String token);

  /// GET /groups/:groupId/time-tracking/workers
  /// Implementation should return [] if 404 (no workers / not provisioned yet).
  Future<List<Worker>> listWorkers(
    String groupId,
    String token, {
    WorkerStatus? status,
    String? month,
  });

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
    String? month,
    DateTime? from,
    DateTime? to,
    double? advanceAmount,
  });

  /// GET /groups/:groupId/time-tracking/totals/active-workers
  /// Optional filters via query params (?from, ?to, ?year, ?month)
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  });

  /// GET /groups/:groupId/time-tracking/totals/history
  /// Query params: from, to, workerId?
  Future<Map<String, dynamic>> getMonthlyPayrollHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String? workerId,
  });

  /// GET /groups/:groupId/time-tracking/totals/working-time-history
  /// Query params: from, to, granularity, workerId?
  Future<WorkingTimeHistoryResponse> getWorkingTimeHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String granularity = 'day',
    String? workerId,
  });

  /// PUT /groups/:groupId/time-tracking/workers/:workerId
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token, {
    String? month,
    DateTime? from,
    DateTime? to,
  });

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

  /// GET /groups/:groupId/time-tracking/export/pdf/preview?from&to&workerId&lang
  Future<Uint8List> previewPayrollPdf(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
    String? lang,
    double? advanceAmount,
  });

  /// GET /groups/:groupId/time-tracking/export/pdf/monthly-calendar
  Future<Uint8List> exportMonthlyCalendarPdf(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? lang,
    double? advanceAmount,
  });

  /// GET /groups/:groupId/time-tracking/import-excel/template?month=YYYY-MM
  Future<Uint8List> downloadExcelImportTemplate(
    String groupId,
    String token, {
    required String month,
  });

  /// GET /groups/:groupId/time-tracking/import/instructions
  Future<WorkingTimeImportInstructions> getImportInstructions(
    String groupId,
    String token,
  );

  /// POST /groups/:groupId/time-tracking/import-excel/preview
  Future<WorkingTimeExcelImportPreview> previewExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required Uint8List fileBytes,
    required String fileName,
  });

  /// POST /groups/:groupId/time-tracking/import-excel/confirm
  Future<WorkingTimeExcelImportConfirmResult> confirmExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required List<WorkingTimeExcelImportEntry> entries,
  });

  /// POST /groups/:groupId/time-tracking/import-json/preview
  Future<WorkingTimeExcelImportPreview> previewJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    required List<Map<String, dynamic>> entries,
  });

  /// POST /groups/:groupId/time-tracking/import-telegram/preview
  Future<Map<String, dynamic>> getTelegramImportSource(
    String groupId,
    String token, {
    required String topicName,
  });

  /// POST /groups/:groupId/time-tracking/import-telegram/preview
  Future<Map<String, dynamic>> previewTelegramImport(
    String groupId,
    String token, {
    required Map<String, dynamic> body,
  });

  /// POST /groups/:groupId/time-tracking/import-json/confirm
  Future<WorkingTimeExcelImportConfirmResult> confirmJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? duplicateStrategy,
    required List<Map<String, dynamic>> entries,
  });
}
