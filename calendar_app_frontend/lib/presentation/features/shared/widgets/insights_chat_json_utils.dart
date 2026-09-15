import 'dart:convert';

Map<String, dynamic> cloneInsightsJsonMap(Map<String, dynamic> input) {
  final cloned = jsonDecode(jsonEncode(input));
  if (cloned is Map<String, dynamic>) return cloned;
  if (cloned is Map) {
    return cloned.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
