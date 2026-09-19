import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OcrImportJobMapping {
  const OcrImportJobMapping({
    required this.previewJobId,
    required this.backgroundJobId,
    required this.startedAt,
    required this.type,
    required this.userId,
    required this.groupId,
  });

  final String previewJobId;
  final String backgroundJobId;
  final DateTime startedAt;
  final String type;
  final String userId;
  final String groupId;

  Map<String, dynamic> toJson() => {
        'previewJobId': previewJobId,
        'backgroundJobId': backgroundJobId,
        'startedAt': startedAt.toIso8601String(),
        'type': type,
        'userId': userId,
        'groupId': groupId,
      };

  factory OcrImportJobMapping.fromJson(Map<String, dynamic> json) {
    return OcrImportJobMapping(
      previewJobId: (json['previewJobId'] ?? '').toString(),
      backgroundJobId: (json['backgroundJobId'] ?? '').toString(),
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.now(),
      type: (json['type'] ?? 'OCR_IMPORT').toString(),
      userId: (json['userId'] ?? '').toString(),
      groupId: (json['groupId'] ?? '').toString(),
    );
  }
}

class OcrImportJobMappingStore {
  OcrImportJobMappingStore._();

  static final instance = OcrImportJobMappingStore._();
  static const _key = 'hexora.ocrImportJobMappings.v1';
  Future<void> _mutationQueue = Future<void>.value();

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

  Future<List<OcrImportJobMapping>> loadForScope({
    required String userId,
    required String groupId,
  }) async {
    final uid = userId.trim();
    final gid = groupId.trim();
    if (uid.isEmpty || gid.isEmpty) return const [];
    final all = await loadAll();
    return all
        .where((entry) => entry.userId == uid && entry.groupId == gid)
        .toList(growable: false);
  }

  Future<void> upsert(OcrImportJobMapping mapping) => _serialize(() async {
        final all = await loadAll();
        final next = <OcrImportJobMapping>[
          mapping,
          ...all.where(
            (entry) => entry.backgroundJobId != mapping.backgroundJobId,
          ),
        ].take(20).toList(growable: false);
        await _save(next);
      });

  Future<void> remove(String backgroundJobId) {
    final trimmed = backgroundJobId.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return _serialize(() async {
      final all = await loadAll();
      final next =
          all.where((entry) => entry.backgroundJobId != trimmed).toList();
      await _save(next);
    });
  }

  Future<void> _save(List<OcrImportJobMapping> mappings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(mappings.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> _serialize(Future<void> Function() mutation) {
    final result = _mutationQueue.then((_) => mutation());
    _mutationQueue = result.catchError((_) {});
    return result;
  }
}
