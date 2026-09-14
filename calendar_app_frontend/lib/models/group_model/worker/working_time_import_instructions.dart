import 'package:flutter/foundation.dart';

@immutable
class WorkingTimeImportInstructions {
  const WorkingTimeImportInstructions({
    required this.ok,
    required this.version,
    required this.modes,
    required this.workers,
  });

  final bool ok;
  final int version;
  final Map<String, WorkingTimeImportMode> modes;
  final List<WorkingTimeImportWorkerRef> workers;

  WorkingTimeImportMode? get excelMode => modes['excel'];
  WorkingTimeImportMode? get jsonMode => modes['json'];

  factory WorkingTimeImportInstructions.fromJson(Map<String, dynamic> json) {
    final rawModes = json['modes'];
    final rawWorkers = json['workers'];
    return WorkingTimeImportInstructions(
      ok: json['ok'] == true,
      version: _asInt(json['version']),
      modes: rawModes is Map
          ? rawModes.map(
              (key, value) => MapEntry(
                key.toString(),
                WorkingTimeImportMode.fromJson(
                  Map<String, dynamic>.from((value as Map?) ?? const {}),
                ),
              ),
            )
          : const <String, WorkingTimeImportMode>{},
      workers: rawWorkers is List
          ? rawWorkers
              .whereType<Map>()
              .map(
                (item) => WorkingTimeImportWorkerRef.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeImportWorkerRef>[],
    );
  }
}

@immutable
class WorkingTimeImportMode {
  const WorkingTimeImportMode({
    required this.id,
    required this.label,
    required this.description,
    required this.endpoint,
    required this.rules,
    required this.upload,
    required this.examples,
    this.sheetFormat,
    this.entryFields = const <WorkingTimeImportField>[],
  });

  final String id;
  final String label;
  final String description;
  final WorkingTimeImportEndpoints endpoint;
  final List<String> rules;
  final WorkingTimeImportUpload upload;
  final WorkingTimeImportSheetFormat? sheetFormat;
  final List<WorkingTimeImportField> entryFields;
  final List<WorkingTimeImportExample> examples;

  factory WorkingTimeImportMode.fromJson(Map<String, dynamic> json) {
    final rawRules = json['rules'];
    final rawEntryFields = json['entryFields'];
    final rawExamples = json['examples'];
    return WorkingTimeImportMode(
      id: _asString(json['id']),
      label: _asString(json['label']),
      description: _asString(json['description']),
      endpoint: WorkingTimeImportEndpoints.fromJson(
        Map<String, dynamic>.from((json['endpoint'] as Map?) ?? const {}),
      ),
      rules: rawRules is List
          ? rawRules.map(_asString).where((value) => value.isNotEmpty).toList(
                growable: false,
              )
          : const <String>[],
      upload: WorkingTimeImportUpload.fromJson(
        Map<String, dynamic>.from((json['upload'] as Map?) ?? const {}),
      ),
      sheetFormat: json['sheetFormat'] is Map<String, dynamic>
          ? WorkingTimeImportSheetFormat.fromJson(
              json['sheetFormat'] as Map<String, dynamic>,
            )
          : null,
      entryFields: rawEntryFields is List
          ? rawEntryFields
              .whereType<Map>()
              .map(
                (field) => WorkingTimeImportField.fromJson(
                  Map<String, dynamic>.from(field),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeImportField>[],
      examples: rawExamples is List
          ? rawExamples
              .whereType<Map>()
              .map(
                (example) => WorkingTimeImportExample.fromJson(
                  Map<String, dynamic>.from(example),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeImportExample>[],
    );
  }
}

@immutable
class WorkingTimeImportEndpoints {
  const WorkingTimeImportEndpoints({
    this.preview,
    this.confirm,
    this.template,
  });

  final String? preview;
  final String? confirm;
  final String? template;

  factory WorkingTimeImportEndpoints.fromJson(Map<String, dynamic> json) {
    return WorkingTimeImportEndpoints(
      preview: _asNullableString(json['preview']),
      confirm: _asNullableString(json['confirm']),
      template: _asNullableString(json['template']),
    );
  }
}

@immutable
class WorkingTimeImportUpload {
  const WorkingTimeImportUpload({
    required this.method,
    required this.contentType,
    required this.fields,
  });

  final String method;
  final String contentType;
  final List<WorkingTimeImportField> fields;

  factory WorkingTimeImportUpload.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    return WorkingTimeImportUpload(
      method: _asString(json['method']),
      contentType: _asString(json['contentType']),
      fields: rawFields is List
          ? rawFields
              .whereType<Map>()
              .map(
                (field) => WorkingTimeImportField.fromJson(
                  Map<String, dynamic>.from(field),
                ),
              )
              .toList(growable: false)
          : const <WorkingTimeImportField>[],
    );
  }
}

@immutable
class WorkingTimeImportField {
  const WorkingTimeImportField({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
  });

  final String name;
  final String type;
  final bool required;
  final String description;

  factory WorkingTimeImportField.fromJson(Map<String, dynamic> json) {
    return WorkingTimeImportField(
      name: _asString(json['name']),
      type: _asString(json['type']),
      required: json['required'] == true,
      description: _asString(json['description']),
    );
  }
}

@immutable
class WorkingTimeImportSheetFormat {
  const WorkingTimeImportSheetFormat({
    required this.oneWorkerPerFile,
    required this.headerAliases,
  });

  final bool oneWorkerPerFile;
  final Map<String, List<String>> headerAliases;

  factory WorkingTimeImportSheetFormat.fromJson(Map<String, dynamic> json) {
    final rawAliases = json['headerAliases'];
    return WorkingTimeImportSheetFormat(
      oneWorkerPerFile: json['oneWorkerPerFile'] == true,
      headerAliases: rawAliases is Map
          ? rawAliases.map(
              (key, value) => MapEntry(
                key.toString(),
                value is List
                    ? value.map(_asString).where((item) => item.isNotEmpty).toList(
                          growable: false,
                        )
                    : const <String>[],
              ),
            )
          : const <String, List<String>>{},
    );
  }
}

@immutable
class WorkingTimeImportExample {
  const WorkingTimeImportExample({
    required this.title,
    required this.body,
  });

  final String title;
  final Map<String, dynamic> body;

  factory WorkingTimeImportExample.fromJson(Map<String, dynamic> json) {
    return WorkingTimeImportExample(
      title: _asString(json['title']),
      body: json['body'] is Map
          ? Map<String, dynamic>.from(json['body'] as Map)
          : const <String, dynamic>{},
    );
  }
}

@immutable
class WorkingTimeImportWorkerRef {
  const WorkingTimeImportWorkerRef({
    required this.id,
    required this.displayName,
    this.alias,
    this.status,
  });

  final String id;
  final String displayName;
  final String? alias;
  final String? status;

  factory WorkingTimeImportWorkerRef.fromJson(Map<String, dynamic> json) {
    return WorkingTimeImportWorkerRef(
      id: _asString(json['id']),
      displayName: _asString(json['displayName']),
      alias: _asNullableString(json['alias']),
      status: _asNullableString(json['status']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _asString(dynamic value) {
  return value?.toString().trim() ?? '';
}

String? _asNullableString(dynamic value) {
  final text = _asString(value);
  return text.isEmpty ? null : text;
}
