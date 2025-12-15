/// models/client.dart
import 'package:hexora/a-models/invoice/client_billing.dart';
class GroupClient {
  String id;
  String name;
  String? groupId;

  // Nested contact info
  String? phone;
  String? email;

  bool isActive;
  Map<String, dynamic>? meta;
  ClientBilling? billing;

  // Optional timestamps if your API returns them (Mongoose timestamps: true)
  DateTime? createdAt;
  DateTime? updatedAt;

  GroupClient({
    required this.id,
    required this.name,
    this.groupId,
    this.phone,
    this.email,
    this.isActive = true,
    this.meta,
    this.billing,
    this.createdAt,
    this.updatedAt,
  });

  GroupClient copyWith({
    String? id,
    String? name,
    String? groupId,
    String? phone,
    String? email,
    bool? isActive,
    Map<String, dynamic>? meta,
    ClientBilling? billing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupClient(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      meta: meta ?? this.meta,
      billing: billing ?? this.billing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupId': groupId,
        'contact': {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
        'isActive': isActive,
        if (meta != null) 'meta': meta,
        if (billing != null) 'billing': billing!.toJson(),
        if (createdAt != null)
          'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null)
          'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };

  factory GroupClient.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id'] ?? '').toString();
    final contact = (json['contact'] as Map?)?.cast<String, dynamic>();
    final billingJson = (json['billing'] as Map?)?.cast<String, dynamic>();
    return GroupClient(
      id: rawId,
      name: (json['name'] ?? '').toString(),
      groupId: json['groupId']?.toString(),
      phone: contact?['phone']?.toString(),
      email: contact?['email']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      billing:
          billingJson != null ? ClientBilling.fromJson(billingJson) : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  @override
  String toString() =>
      'Client{id: $id, name: $name, groupId: $groupId, phone: $phone, email: $email, isActive: $isActive}';

  @override
  bool operator ==(Object other) =>
      other is GroupClient &&
      other.id == id &&
      other.name == name &&
      other.groupId == groupId;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ (groupId?.hashCode ?? 0);
}
