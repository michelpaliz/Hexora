import 'package:meta/meta.dart';

@immutable
class TimeEntry {
  final String id; // server-generated
  final String workerId; // FK to Worker
  final DateTime start; // ISO8601
  final DateTime? end; // null if running/open
  final int? durationMinutes; // optional; server may compute
  final String? notes; // optional
  final DateTime? createdAt; // optional server timestamps
  final DateTime? updatedAt;

  const TimeEntry({
    required this.id,
    required this.workerId,
    required this.start,
    this.end,
    this.durationMinutes,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenient constructor for a "new" entry before the server assigns an id.
  /// Use this when calling create; `toCreateJson()` ignores `id`.
  factory TimeEntry.newEntry({
    required String workerId,
    required DateTime start,
    DateTime? end,
    String? notes,
  }) {
    return TimeEntry(
      id: '', // placeholder; server will return a real id
      workerId: workerId,
      start: start,
      end: end,
      notes: notes,
    );
  }

  /// Parse from backend JSON.
  /// Adjust keys if your API uses different names.
  factory TimeEntry.fromJson(Map<String, dynamic> json) {
    // Accept both camelCase and snake_case just in case.
    String? _s(String a, String b) => (json[a] ?? json[b])?.toString();

    DateTime? _parseDT(dynamic v) {
      if (v == null) return null;
      // Ensure DateTime.parse handles Z/offset (ISO 8601)
      return DateTime.parse(v.toString());
    }

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return TimeEntry(
      id: _s('id', '_id') ?? '',
      workerId: _s('workerId', 'worker_id') ?? '',
      start: _parseDT(json['start'] ?? json['startedAt'])!,
      end: _parseDT(json['end'] ?? json['endedAt']),
      durationMinutes:
          _int(json['durationMinutes'] ?? json['duration_minutes']),
      notes: json['notes'] as String?,
      createdAt: _parseDT(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDT(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'workerId': workerId,
        'start': start.toUtc().toIso8601String(),
        if (end != null) 'end': end!.toUtc().toIso8601String(),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (notes != null) 'notes': notes,
        if (createdAt != null)
          'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };
  Map<String, dynamic> toCreateJson() => {
        'workerId': workerId,
        'startedAt':
            start.toUtc().toIso8601String(), // 🔁 changed "start" → "startedAt"
        if (end != null)
          'endedAt':
              end!.toUtc().toIso8601String(), // 🔁 changed "end" → "endedAt"
        if (notes != null) 'notes': notes,
      };

  /// Handy computed duration if end is present and server didn’t send one.
  int? get computedDurationMinutes {
    if (durationMinutes != null) return durationMinutes;
    if (end == null) return null;
    return end!.difference(start).inMinutes;
  }

  TimeEntry copyWith({
    String? id,
    String? workerId,
    DateTime? start,
    DateTime? end,
    int? durationMinutes,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeEntry(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      start: start ?? this.start,
      end: end ?? this.end,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
