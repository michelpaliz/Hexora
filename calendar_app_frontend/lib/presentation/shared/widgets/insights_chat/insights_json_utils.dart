import 'dart:convert';

Map<String, dynamic>? safeMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return null;
}
int? readInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool isFiniteNum(dynamic value) {
  return value is num && value.isFinite;
}
Map<String, dynamic> cloneJsonMap(Map<String, dynamic> input) {
  final cloned = jsonDecode(jsonEncode(input));
  if (cloned is Map<String, dynamic>) return cloned;
  if (cloned is Map) {
    return cloned.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
