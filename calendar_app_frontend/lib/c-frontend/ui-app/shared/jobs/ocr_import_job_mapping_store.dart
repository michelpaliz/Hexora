import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OcrImportJobMapping {
  const OcrImportJobMapping({
    required this.previewJobId,
    required this.backgroundJobId,
    required this.startedAt,
    required this.type,
  });

  final String previewJobId;
  final String backgroundJobId;
  final DateTime startedAt;
  final String type;

  Map<String, dynamic> toJson() => {
        'previewJobId': previewJobId,
        'backgroundJobId': backgroundJobId,
        'startedAt': startedAt.toIso8601String(),
        'type': type,
      };

  factory OcrImportJobMapping.fromJson(Map<String, dynamic> json) {
    return OcrImportJobMapping(
      previewJobId: (json['previewJobId'] ?? '').toString(),
      backgroundJobId: (json['backgroundJobId'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.now(),
      type: (json['type'] ?? 'OCR_IMPORT').toString(),
    );
  }
}

class OcrImportJobMappingStore {
  const OcrImportJobMappingStore._();

  static const instance = OcrImportJobMappingStore._();
  static const _key = 'hexora.ocrImportJobMappings.v1';

  Future<List<OcrImportJobMapping>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((entry) => OcrImportJobMapping.fromJson(
                Map<String, dynamic>.from(entry),
              ))
          .where((entry) =>
              entry.previewJobId.trim().isNotEmpty &&
              entry.backgroundJobId.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<OcrImportJobMapping?> findByBackgroundJobId(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final all = await loadAll();
    for (final entry in all) {
      if (entry.backgroundJobId == trimmed) return entry;
    }
    return null;
  }

  Future<void> upsert(OcrImportJobMapping mapping) async {
    final all = await loadAll();
    final next = <OcrImportJobMapping>[
      mapping,
      ...all.where((entry) => entry.backgroundJobId != mapping.backgroundJobId),
    ].take(20).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> remove(String backgroundJobId) async {
    final trimmed = backgroundJobId.trim();
    if (trimmed.isEmpty) return;
    final all = await loadAll();
    final next =
        all.where((entry) => entry.backgroundJobId != trimmed).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(next.map((entry) => entry.toJson()).toList()),
    );
  }
}
