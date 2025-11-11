/// Global helpers to normalize Mongo Extended JSON IDs to plain strings.
/// Examples handled:
///   "6806..."                      -> "6806..."
///   { "$oid": "6806..." }          -> "6806..."
///   12345                          -> "12345"
///   null                           -> ""
library id_normalizer;

/// Normalize a single id-like value to a plain String.
String normalizeId(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map && v[r'$oid'] is String) return v[r'$oid'] as String;
  return v.toString();
}

/// Normalize a list of id-like values to List<String>.
List<String> normalizeIdList(dynamic v) {
  if (v == null) return const <String>[];
  if (v is List) return v.map(normalizeId).toList();
  // Non-list input -> empty list (safe default)
  return const <String>[];
}

/// Normalize the KEYS of a map that are id-like (e.g., userRoles).
/// Values are kept as-is (you can post-process them if needed).
Map<String, V> normalizeIdMapKeys<V>(Map<dynamic, V>? m) {
  if (m == null) return <String, V>{};
  return m.map((k, v) => MapEntry(normalizeId(k), v));
}

/// Normalize the VALUES of a map (when values are id-like objects/strings).
Map<K, String> normalizeIdMapValues<K>(Map<K, dynamic>? m) {
  if (m == null) return <K, String>{};
  return m.map((k, v) => MapEntry(k, normalizeId(v)));
}

/// Convenience: normalize both keys (ids) and lowercase string values.
/// Useful for maps like userRoles: { userId: "owner" | "admin" | ... }.
Map<String, String> normalizeUserRoleWireMap(Map<dynamic, dynamic>? m) {
  if (m == null) return <String, String>{};
  final out = <String, String>{};
  m.forEach((k, v) {
    final key = normalizeId(k);
    final val =
        (v is String) ? v.toLowerCase() : v?.toString().toLowerCase() ?? '';
    if (key.isNotEmpty && val.isNotEmpty) out[key] = val;
  });
  return out;
}
