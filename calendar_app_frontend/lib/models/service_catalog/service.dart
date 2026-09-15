/// models/service.dart
class Service {
  String id;
  String name;
  String? groupId;

  int? defaultMinutes; // e.g., 45
  String? color; // e.g., "#3b82f6"
  bool isActive;
  Map<String, dynamic>? meta;

  // Optional timestamps (Mongoose timestamps: true)
  DateTime? createdAt;
  DateTime? updatedAt;

  Service({
    required this.id,
    required this.name,
    this.groupId,
    this.defaultMinutes,
    this.color,
    this.isActive = true,
    this.meta,
    this.createdAt,
    this.updatedAt,
  });

  Service copyWith({
    String? id,
    String? name,
    String? groupId,
    int? defaultMinutes,
    String? color,
    bool? isActive,
    Map<String, dynamic>? meta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      defaultMinutes: defaultMinutes ?? this.defaultMinutes,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      meta: meta ?? this.meta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupId': groupId,
        if (defaultMinutes != null) 'defaultMinutes': defaultMinutes,
        if (color != null) 'color': color,
        'isActive': isActive,
        if (meta != null) 'meta': meta,
        if (createdAt != null)
          'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };

  factory Service.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id'] ?? '').toString();
    return Service(
      id: rawId,
      name: (json['name'] ?? '').toString(),
      groupId: json['groupId']?.toString(),
      defaultMinutes: json['defaultMinutes'] is num
          ? (json['defaultMinutes'] as num).toInt()
          : null,
      color: json['color']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  String toString() =>
      'Service{id: $id, name: $name, groupId: $groupId, defaultMinutes: $defaultMinutes, color: $color, isActive: $isActive}';

  @override
  bool operator ==(Object other) =>
      other is Service &&
      other.id == id &&
      other.name == name &&
      other.groupId == groupId;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ (groupId?.hashCode ?? 0);
}
