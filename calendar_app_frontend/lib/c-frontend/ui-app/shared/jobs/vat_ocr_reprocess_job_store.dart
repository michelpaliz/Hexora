import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VatOcrReprocessJobRef {
  final String jobId;
  final String groupId;
  final DateTime startedAt;

  const VatOcrReprocessJobRef({
    required this.jobId,
    required this.groupId,
    required this.startedAt,
  });

  Map<String, dynamic> toJson() => {
        'jobId': jobId,
        'groupId': groupId,
        'startedAt': startedAt.toIso8601String(),
      };

  static VatOcrReprocessJobRef? fromJson(Map<String, dynamic> json) {
    final jobId = (json['jobId'] ?? '').toString().trim();
    final groupId = (json['groupId'] ?? '').toString().trim();
    if (jobId.isEmpty || groupId.isEmpty) return null;
    return VatOcrReprocessJobRef(
      jobId: jobId,
      groupId: groupId,
      startedAt: DateTime.tryParse((json['startedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class VatOcrReprocessJobStore {
  static const _keyPrefix = 'hexora.vat_ocr_reprocess.active.';

  static Future<void> save(VatOcrReprocessJobRef job) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_keyPrefix${job.groupId}', jsonEncode(job.toJson()));
  }

  static Future<VatOcrReprocessJobRef?> read(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix${groupId.trim()}');
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return VatOcrReprocessJobRef.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<void> clear(String groupId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix${groupId.trim()}');
  }
}
