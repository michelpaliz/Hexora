/// models/service.dart
class Service {
  String id;
  String name;
  String? groupId;

  int? defaultMinutes; // e.g., 45
  String? color; // e.g., "#3b82f6"
  bool isActive;
  Map<String, dynamic>? meta;
  String workEnvironment; // indoor | outdoor | mixed
  bool weatherSensitive;

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
    this.workEnvironment = 'indoor',
    this.weatherSensitive = false,
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
    String? workEnvironment,
    bool? weatherSensitive,
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
      workEnvironment: workEnvironment ?? this.workEnvironment,
      weatherSensitive: weatherSensitive ?? this.weatherSensitive,
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
        if (workEnvironment != 'unspecified') 'workEnvironment': workEnvironment,
        'weatherSensitive': weatherSensitive,
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
      workEnvironment: json['workEnvironment']?.toString() ?? 'unspecified',
      weatherSensitive: json['weatherSensitive'] == true,
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
