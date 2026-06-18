// models/client.dart
import 'package:hexora/a-models/invoice/client_billing.dart';

class GroupClient {
  String id;
  String name;
  String? groupId;

  /// Optional client classification (free text, lowercase suggested)
  String? entityType;

  /// Optional property type classification (free text, lowercase suggested)
  String? propertyKind;

  // Nested contact info
  String? phone;
  String? email;

  bool isActive;
  Map<String, dynamic>? meta;
  ClientBilling? billing;
  bool? hasCurrentMonthInvoice;
  bool? missingCurrentMonthInvoice;
  int? currentMonthInvoiceCount;
  DateTime? lastCurrentMonthInvoiceAt;

  // Optional timestamps if your API returns them (Mongoose timestamps: true)
  DateTime? createdAt;
  DateTime? updatedAt;

  GroupClient({
    required this.id,
    required this.name,
    this.groupId,
    this.entityType,
    this.propertyKind,
    this.phone,
    this.email,
    this.isActive = true,
    this.meta,
    this.billing,
    this.hasCurrentMonthInvoice,
    this.missingCurrentMonthInvoice,
    this.currentMonthInvoiceCount,
    this.lastCurrentMonthInvoiceAt,
    this.createdAt,
    this.updatedAt,
  });

  GroupClient copyWith({
    String? id,
    String? name,
    String? groupId,
    String? entityType,
    String? propertyKind,
    String? phone,
    String? email,
    bool? isActive,
    Map<String, dynamic>? meta,
    ClientBilling? billing,
    bool? hasCurrentMonthInvoice,
    bool? missingCurrentMonthInvoice,
    int? currentMonthInvoiceCount,
    DateTime? lastCurrentMonthInvoiceAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupClient(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      entityType: entityType ?? this.entityType,
      propertyKind: propertyKind ?? this.propertyKind,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      meta: meta ?? this.meta,
      billing: billing ?? this.billing,
      hasCurrentMonthInvoice:
          hasCurrentMonthInvoice ?? this.hasCurrentMonthInvoice,
      missingCurrentMonthInvoice:
          missingCurrentMonthInvoice ?? this.missingCurrentMonthInvoice,
      currentMonthInvoiceCount:
          currentMonthInvoiceCount ?? this.currentMonthInvoiceCount,
      lastCurrentMonthInvoiceAt:
          lastCurrentMonthInvoiceAt ?? this.lastCurrentMonthInvoiceAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'groupId': groupId,
        if (entityType != null) 'entityType': entityType,
        if (propertyKind != null) 'propertyKind': propertyKind,
        'contact': {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
        'isActive': isActive,
        if (meta != null) 'meta': meta,
        if (billing != null) 'billing': billing!.toJson(),
        if (hasCurrentMonthInvoice != null)
          'hasCurrentMonthInvoice': hasCurrentMonthInvoice,
        if (missingCurrentMonthInvoice != null)
          'missingCurrentMonthInvoice': missingCurrentMonthInvoice,
        if (currentMonthInvoiceCount != null)
          'currentMonthInvoiceCount': currentMonthInvoiceCount,
        if (lastCurrentMonthInvoiceAt != null)
          'lastCurrentMonthInvoiceAt':
              lastCurrentMonthInvoiceAt!.toUtc().toIso8601String(),
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
      entityType: json['entityType']?.toString(),
      propertyKind: json['propertyKind']?.toString(),
      phone: contact?['phone']?.toString(),
      email: contact?['email']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      billing:
          billingJson != null ? ClientBilling.fromJson(billingJson) : null,
      hasCurrentMonthInvoice:
          _parseBool(json['hasCurrentMonthInvoice'] ?? json['has_current_month_invoice']),
      missingCurrentMonthInvoice: _parseBool(
        json['missingCurrentMonthInvoice'] ??
            json['missing_current_month_invoice'],
      ),
      currentMonthInvoiceCount: _parseInt(
        json['currentMonthInvoiceCount'] ??
            json['current_month_invoice_count'],
      ),
      lastCurrentMonthInvoiceAt: _parseDate(
        json['lastCurrentMonthInvoiceAt'] ??
            json['last_current_month_invoice_at'],
      ),
      createdAt:
          _parseDate(json['createdAt']),
      updatedAt:
          _parseDate(json['updatedAt']),
    );
  }

  bool get hasCurrentMonthInvoiceFlagData =>
      hasCurrentMonthInvoice != null ||
      missingCurrentMonthInvoice != null ||
      currentMonthInvoiceCount != null ||
      lastCurrentMonthInvoiceAt != null;

  bool get isMissingCurrentMonthInvoice => missingCurrentMonthInvoice == true;

  bool get hasIssuedInvoiceThisMonth =>
      hasCurrentMonthInvoice == true ||
      (currentMonthInvoiceCount ?? 0) > 0 ||
      lastCurrentMonthInvoiceAt != null;

  @override
  String toString() =>
      'Client{id: $id, name: $name, groupId: $groupId, entityType: $entityType, propertyKind: $propertyKind, phone: $phone, email: $email, isActive: $isActive}';

  @override
  bool operator ==(Object other) =>
      other is GroupClient &&
      other.id == id &&
      other.name == name &&
      other.groupId == groupId &&
      other.entityType == entityType &&
      other.propertyKind == propertyKind;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (groupId?.hashCode ?? 0) ^
      (entityType?.hashCode ?? 0) ^
      (propertyKind?.hashCode ?? 0);
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
