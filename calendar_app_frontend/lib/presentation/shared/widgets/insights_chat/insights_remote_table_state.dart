import 'insights_json_utils.dart';

class InsightsRemoteTableState {
  InsightsRemoteTableState({this.pageSize = 50});

  Map<String, dynamic>? table;
  Map<String, dynamic>? pagination;
  bool loading = false;
  String? error;
  int requestSerial = 0;
  bool loadedOnce = false;
  int page = 1;
  int pageSize;

  int get totalRows =>
      readInt(pagination?['totalRows']) ??
      readInt(table?['totalAvailable']) ??
      0;

  int get totalPages =>
      (readInt(pagination?['totalPages']) ?? 1).clamp(1, 999999).toInt();

  int get effectivePage =>
      (readInt(pagination?['page']) ?? page).clamp(1, totalPages).toInt();

  int get effectivePageSize =>
      (readInt(pagination?['pageSize']) ?? pageSize).clamp(1, 500).toInt();
}
