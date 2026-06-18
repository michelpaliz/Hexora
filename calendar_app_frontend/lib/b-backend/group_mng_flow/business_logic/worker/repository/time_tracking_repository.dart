import 'dart:typed_data';

import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/working_time_excel_import.dart';
import 'package:hexora/a-models/group_model/worker/working_time_history.dart';
import 'package:hexora/a-models/group_model/worker/working_time_import_instructions.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/i_time_tracking_api_client.dart';

//Public app level abstraction
abstract class ITimeTrackingRepository {
  Future<void> enable(String groupId, String token);
  Future<void> disable(String groupId, String token);

  Future<List<Worker>> getWorkers(
    String groupId,
    String token, {
    WorkerStatus? status,
    String? month,
  });
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
    String? month,
    DateTime? from,
    DateTime? to,
    double? advanceAmount,
  });
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  });
  Future<Map<String, dynamic>> getMonthlyPayrollHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String? workerId,
  });
  Future<WorkingTimeHistoryResponse> getWorkingTimeHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String granularity = 'day',
    String? workerId,
  });
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token, {
    String? month,
    DateTime? from,
    DateTime? to,
  });

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

  Future<Uint8List> previewPayrollPdf(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
    String? lang,
    double? advanceAmount,
  });

  Future<Uint8List> downloadExcelImportTemplate(
    String groupId,
    String token, {
    required String month,
  });

  Future<WorkingTimeImportInstructions> getImportInstructions(
    String groupId,
    String token,
  );

  Future<WorkingTimeExcelImportPreview> previewExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required Uint8List fileBytes,
    required String fileName,
  });

  Future<WorkingTimeExcelImportConfirmResult> confirmExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required List<WorkingTimeExcelImportEntry> entries,
  });

  Future<WorkingTimeExcelImportPreview> previewJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    required List<Map<String, dynamic>> entries,
  });

  Future<Map<String, dynamic>> getTelegramImportSource(
    String groupId,
    String token, {
    required String topicName,
  });

  Future<Map<String, dynamic>> previewTelegramImport(
    String groupId,
    String token, {
    required Map<String, dynamic> body,
  });

  Future<WorkingTimeExcelImportConfirmResult> confirmJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? duplicateStrategy,
    required List<Map<String, dynamic>> entries,
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
  Future<List<Worker>> getWorkers(
    String groupId,
    String token, {
    WorkerStatus? status,
    String? month,
  }) =>
      _api.listWorkers(groupId, token, status: status, month: month);

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
    String? month,
    DateTime? from,
    DateTime? to,
    double? advanceAmount,
  }) =>
      _api.getWorkerTotals(
        groupId,
        token,
        workerId: workerId,
        month: month,
        from: from,
        to: to,
        advanceAmount: advanceAmount,
      );

  @override
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) =>
      _api.getActiveWorkersTotals(
        groupId,
        token,
        from: from,
        to: to,
        year: year,
        month: month,
      );

  @override
  Future<Map<String, dynamic>> getMonthlyPayrollHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String? workerId,
  }) =>
      _api.getMonthlyPayrollHistory(
        groupId,
        token,
        from: from,
        to: to,
        workerId: workerId,
      );

  @override
  Future<WorkingTimeHistoryResponse> getWorkingTimeHistory(
    String groupId,
    String token, {
    required DateTime from,
    required DateTime to,
    String granularity = 'day',
    String? workerId,
  }) =>
      _api.getWorkingTimeHistory(
        groupId,
        token,
        from: from,
        to: to,
        granularity: granularity,
        workerId: workerId,
      );

  @override
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token, {
    String? month,
    DateTime? from,
    DateTime? to,
  }) =>
      _api.updateWorker(
        groupId,
        workerId,
        worker,
        token,
        month: month,
        from: from,
        to: to,
      );

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

  @override
  Future<Uint8List> previewPayrollPdf(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
    String? lang,
    double? advanceAmount,
  }) =>
      _api.previewPayrollPdf(
        groupId,
        token,
        from: from,
        to: to,
        workerId: workerId,
        lang: lang,
        advanceAmount: advanceAmount,
      );

  @override
  Future<Uint8List> downloadExcelImportTemplate(
    String groupId,
    String token, {
    required String month,
  }) =>
      _api.downloadExcelImportTemplate(
        groupId,
        token,
        month: month,
      );

  @override
  Future<WorkingTimeImportInstructions> getImportInstructions(
    String groupId,
    String token,
  ) =>
      _api.getImportInstructions(groupId, token);

  @override
  Future<WorkingTimeExcelImportPreview> previewExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required Uint8List fileBytes,
    required String fileName,
  }) =>
      _api.previewExcelImport(
        groupId,
        token,
        workerId: workerId,
        month: month,
        fileBytes: fileBytes,
        fileName: fileName,
      );

  @override
  Future<WorkingTimeExcelImportConfirmResult> confirmExcelImport(
    String groupId,
    String token, {
    required String workerId,
    required String month,
    required List<WorkingTimeExcelImportEntry> entries,
  }) =>
      _api.confirmExcelImport(
        groupId,
        token,
        workerId: workerId,
        month: month,
        entries: entries,
      );

  @override
  Future<WorkingTimeExcelImportPreview> previewJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    required List<Map<String, dynamic>> entries,
  }) =>
      _api.previewJsonImport(
        groupId,
        token,
        month: month,
        workerId: workerId,
        entries: entries,
      );

  @override
  Future<Map<String, dynamic>> getTelegramImportSource(
    String groupId,
    String token, {
    required String topicName,
  }) =>
      _api.getTelegramImportSource(
        groupId,
        token,
        topicName: topicName,
      );

  @override
  Future<Map<String, dynamic>> previewTelegramImport(
    String groupId,
    String token, {
    required Map<String, dynamic> body,
  }) =>
      _api.previewTelegramImport(
        groupId,
        token,
        body: body,
      );

  @override
  Future<WorkingTimeExcelImportConfirmResult> confirmJsonImport(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? duplicateStrategy,
    required List<Map<String, dynamic>> entries,
  }) =>
      _api.confirmJsonImport(
        groupId,
        token,
        month: month,
        workerId: workerId,
        duplicateStrategy: duplicateStrategy,
        entries: entries,
      );
}
