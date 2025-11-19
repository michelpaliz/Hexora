part of 'package:hexora/a-models/user_model/user.dart';

String requireString(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is String && v.isNotEmpty) return v;
  throw FormatException("Expected non-empty string for '$key', got: $v");
}

String requireStringAny(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v is String && v.isNotEmpty) return v;
  }
  throw FormatException(
      "Expected non-empty string for one of ${keys.join(', ')}, got: ${keys.map((k) => j[k]).toList()}");
}

String? optString(Map<String, dynamic> j, String key) {
  final v = j[key];
  return v is String ? v : null;
}

List<String> optStringList(Map<String, dynamic> j, String key) {
  final v = j[key];
  if (v is List) {
    return v.map((e) => e.toString()).toList();
  }
  return <String>[];
}

// Returns first non-empty string among keys, else null
String? optStringAny(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

Map<String, dynamic> unwrapUser(Map<String, dynamic> raw) {
  for (final key in ['user', 'data', 'profile', 'result']) {
    final v = raw[key];
    if (v is Map) return v.cast<String, dynamic>();
  }
  return raw;
}
