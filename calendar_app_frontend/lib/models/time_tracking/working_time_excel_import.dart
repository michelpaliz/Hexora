import 'package:flutter/foundation.dart';

@immutable
class WorkingTimeExcelImportPreview {
  const WorkingTimeExcelImportPreview({
    required this.ok,
    required this.fileName,
    required this.worker,
    required this.month,
    required this.timeZone,
    required this.sheetName,
    required this.rowCount,
    required this.validRowCount,
    required this.invalidRowCount,
    required this.warnings,
    required this.entries,
  });

  final bool ok;
  final String? fileName;
  final WorkingTimeExcelImportWorker? worker;
  final String month;
  final String? timeZone;
  final String? sheetName;
  final int rowCount;
  final int validRowCount;
  final int invalidRowCount;
  final List<String> warnings;
  final List<WorkingTimeExcelImportEntry> entries;

  bool get hasInvalidRows =>
      invalidRowCount > 0 || entries.any((entry) => entry.issues.isNotEmpty);

  bool get hasWarnings => warnings.isNotEmpty;

  factory WorkingTimeExcelImportPreview.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    final rawWarnings = json['warnings'];
    return WorkingTimeExcelImportPreview(
      ok: json['ok'] == true,
      fileName: _asNullableString(json['fileName']),
      worker: json['worker'] is Map<String, dynamic>
          ? WorkingTimeExcelImportWorker.fromJson(
              json['worker'] as Map<String, dynamic>,
            )
          : null,
      month: (json['month'] ?? '').toString(),
      timeZone: _asNullableString(json['timeZone']),
      sheetName: _asNullableString(json['sheetName']),
      rowCount: _asInt(json['rowCount']),
      validRowCount: _asInt(json['validRowCount']),
      invalidRowCount: _asInt(json['invalidRowCount']),
      warnings: rawWarnings is List
          ? rawWarnings
              .map(_stringifyIssue)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      entries: rawEntries is List
          ? rawEntries
              .whereType<Map>()
              .map((entry) => WorkingTimeExcelImportEntry.fromJson(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList(growable: false)
          : const <WorkingTimeExcelImportEntry>[],
    );
  }
}

@immutable
class WorkingTimeExcelImportWorker {
  const WorkingTimeExcelImportWorker({
    required this.id,
    required this.displayName,
    required this.status,
  });

  final String id;
  final String displayName;
  final String? status;

  factory WorkingTimeExcelImportWorker.fromJson(Map<String, dynamic> json) {
    return WorkingTimeExcelImportWorker(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      displayName: (json['displayName'] ?? json['name'] ?? '').toString(),
      status: _asNullableString(json['status']),
    );
  }
}

@immutable
class WorkingTimeExcelImportEntry {
  const WorkingTimeExcelImportEntry({
    required this.rowNumber,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    required this.notes,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    required this.issues,
  });

  final int rowNumber;
  final String date;
  final String startTime;
  final String endTime;
  final int breakMinutes;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final List<String> issues;

  bool get isValid => issues.isEmpty;

  factory WorkingTimeExcelImportEntry.fromJson(Map<String, dynamic> json) {
    final rawIssues = json['issues'];
    return WorkingTimeExcelImportEntry(
      rowNumber: _asInt(json['rowNumber']),
      date: (json['date'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      breakMinutes: _asInt(json['breakMinutes']),
      notes: _asNullableString(json['notes']),
      startedAt: _asDateTime(json['startedAt']),
      endedAt: _asDateTime(json['endedAt']),
      durationMinutes: _asInt(json['durationMinutes']),
      issues: rawIssues is List
          ? rawIssues
              .map(_stringifyIssue)
              .where((value) => value.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rowNumber': rowNumber,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'breakMinutes': breakMinutes,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
      if (startedAt != null) 'startedAt': startedAt!.toUtc().toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toUtc().toIso8601String(),
      'durationMinutes': durationMinutes,
      'issues': issues,
    };
  }
}

@immutable
class WorkingTimeExcelImportConfirmResult {
  const WorkingTimeExcelImportConfirmResult({
    required this.importedCount,
    required this.requestId,
    required this.raw,
    this.skippedCount = 0,
    this.skippedEntries = const <Map<String, dynamic>>[],
  });

  final int importedCount;
  final int skippedCount;
  final List<Map<String, dynamic>> skippedEntries;
  final String? requestId;
  final Map<String, dynamic> raw;

  factory WorkingTimeExcelImportConfirmResult.fromJson(
    Map<String, dynamic> json, {
    required int fallbackImportedCount,
  }) {
    return WorkingTimeExcelImportConfirmResult(
      importedCount: _asPositiveInt(
            json['importedCount'] ??
                json['createdCount'] ??
                json['count'] ??
                json['entriesCount'],
          ) ??
          fallbackImportedCount,
      skippedCount: _asPositiveInt(json['skippedCount']) ?? 0,
      skippedEntries: _mapList(json['skippedEntries']),
      requestId: _asNullableString(json['requestId']),
      raw: json,
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asPositiveInt(dynamic value) {
  if (value == null) return null;
  final parsed = _asInt(value);
  return parsed >= 0 ? parsed : null;
}

String? _asNullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _asDateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String _stringifyIssue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is Map) {
    final message =
        value['message'] ?? value['error'] ?? value['detail'] ?? value['code'];
    return message?.toString().trim() ?? '';
  }
  return value.toString().trim();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}
