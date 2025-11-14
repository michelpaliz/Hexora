// lib/c-frontend/d-event-section/screens/event_detail/helpers/readable.dart
typedef IdResolver = String? Function(String id);

/// Returns a human-readable label for an ID.
/// Priority: resolver → names map → fallback → original id (if fallback not provided).
String readableId(
  String? id, {
  IdResolver? resolver,
  Map<String, String>? names,
  String? fallback, // <- NEW (null keeps old behavior)
}) {
  if (id == null || id.trim().isEmpty) return fallback ?? '';

  // 1) Try resolver
  final viaResolver = resolver?.call(id);
  if (viaResolver != null && viaResolver.trim().isNotEmpty) {
    return viaResolver.trim();
  }

  // 2) Try names map
  final viaMap = names?[id];
  if (viaMap != null && viaMap.trim().isNotEmpty) {
    return viaMap.trim();
  }

  // 3) Fallback if provided, else original id (back-compat)
  return (fallback != null) ? fallback : id;
}
