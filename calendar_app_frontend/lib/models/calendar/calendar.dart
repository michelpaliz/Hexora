/// models/calendar.dart
class Calendar {
  // Core
  String id;
  String name;

  // Relations
  String? groupId; // nullable: some calendars may be personal or not yet linked

  // Behavior / display
  /// 'simple' | 'work_visit'
  String defaultType;
  String timezone;          // e.g. "Europe/Madrid"
  String? color;            // hex or theme token, nullable
  /// 'private' | 'shared'
  String visibility;
  bool isArchived;
  int order;

  // Optional timestamps if your API returns them (Mongoose timestamps: true)
  DateTime? createdAt;
  DateTime? updatedAt;

  Calendar({
    required this.id,
    required this.name,
    this.groupId,
    this.defaultType = CalendarType.simple,
    this.timezone = 'Europe/Madrid',
    this.color,
    this.visibility = CalendarVisibility.shared,
    this.isArchived = false,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  // ---------- Copy ----------
  Calendar copyWith({
    String? id,
    String? name,
    String? groupId,
    String? defaultType,
    String? timezone,
    String? color,
    String? visibility,
    bool? isArchived,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Calendar(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      defaultType: defaultType ?? this.defaultType,
      timezone: timezone ?? this.timezone,
      color: color ?? this.color,
      visibility: visibility ?? this.visibility,
      isArchived: isArchived ?? this.isArchived,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------- JSON ----------
  Map<String, dynamic> toJson() {
    return {
      'id': id,                // backend now returns `id` (string)
      'name': name,
      'groupId': groupId,
      'defaultType': defaultType,
      'timezone': timezone,
      'color': color,
      'visibility': visibility,
      'isArchived': isArchived,
      'order': order,
      if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    };
  }

  factory Calendar.fromJson(Map<String, dynamic> json) {
    // Accept both `id` and legacy `_id`
    final rawId = (json['id'] ?? json['_id'] ?? '').toString();

    // Accept legacy eventIds but ignore them (removed in new model)
    // final _ = json['eventIds']; // intentionally unused

    return Calendar(
      id: rawId,
      name: (json['name'] ?? '').toString(),
      groupId: json['groupId']?.toString(),
      defaultType: (json['defaultType'] ?? CalendarType.simple).toString(),
      timezone: (json['timezone'] ?? 'Europe/Madrid').toString(),
      color: json['color']?.toString(),
      visibility: (json['visibility'] ?? CalendarVisibility.shared).toString(),
      isArchived: json['isArchived'] is bool ? json['isArchived'] as bool : false,
      order: json['order'] is num ? (json['order'] as num).toInt() : 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // ---------- Defaults ----------
  static Calendar defaultCalendar() {
    return Calendar(
      id: 'default_calendar_id',
      name: 'Default Calendar',
      defaultType: CalendarType.simple,
      timezone: 'Europe/Madrid',
      visibility: CalendarVisibility.shared,
      isArchived: false,
      order: 0,
    );
  }

  @override
  String toString() {
    return 'Calendar{id: $id, name: $name, groupId: $groupId, '
        'defaultType: $defaultType, timezone: $timezone, color: $color, '
        'visibility: $visibility, isArchived: $isArchived, order: $order, '
        'createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) {
    return other is Calendar &&
        other.id == id &&
        other.name == name &&
        other.defaultType == defaultType &&
        other.timezone == timezone &&
        other.visibility == visibility &&
        other.isArchived == isArchived &&
        other.order == order &&
        other.groupId == groupId &&
        other.color == color;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (groupId?.hashCode ?? 0) ^
      defaultType.hashCode ^
      timezone.hashCode ^
      (color?.hashCode ?? 0) ^
      visibility.hashCode ^
      isArchived.hashCode ^
      order.hashCode;
}

class CalendarType {
  static const String simple = 'simple';
  static const String workVisit = 'work_visit';
}

class CalendarVisibility {
  static const String private = 'private';
  static const String shared = 'shared';
}
