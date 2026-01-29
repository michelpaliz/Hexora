String readId(dynamic v) {
  if (v == null) return '';
  if (v is Map) {
    final oid = v[r'$oid'];
    if (oid != null) return oid.toString();
    final id = v['id'] ?? v['_id'];
    if (id != null) return id.toString();
  }
  return v.toString();
}

String? readIdOrNull(dynamic v) {
  final id = readId(v).trim();
  return id.isEmpty ? null : id;
}

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) {
    // Treat seconds as ms if too small.
    if (v < 10000000000) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
    return DateTime.fromMillisecondsSinceEpoch(v);
  }
  if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  if (v is Map && v[r'$date'] is String) {
    return DateTime.tryParse(v[r'$date'] as String);
  }
  if (v is Map && v[r'$date'] is num) {
    return DateTime.fromMillisecondsSinceEpoch((v[r'$date'] as num).toInt());
  }
  return null;
}

bool? parseBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == 'true' || s == '1' || s == 'yes' || s == 'y') return true;
    if (s == 'false' || s == '0' || s == 'no' || s == 'n') return false;
  }
  return null;
}

int? parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

List<String> parseStringList(dynamic v) {
  if (v == null) return const [];
  if (v is List) {
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  final s = v.toString().trim();
  if (s.isEmpty) return const [];
  return [s];
}
