// lib/models/category/event_category.dart
class EventCategory {
  final String id;
  final String name;
  final String? parentId;
  final String? color;
  final String? icon;

  EventCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.color,
    this.icon,
  });

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: (map['id'] ?? map['_id']).toString(),
      name: (map['name'] ?? '').toString(),
      parentId: map['parentId']?.toString(),
      color: map['color']?.toString(),
      icon: map['icon']?.toString(),
    );
  }

  Map<String, dynamic> toBackendCreateJson() => {
        'name': name,
        if (parentId != null) 'parentId': parentId,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
      };

  EventCategory copyWith({
    String? id,
    String? name,
    String? parentId,
    String? color,
    String? icon,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
