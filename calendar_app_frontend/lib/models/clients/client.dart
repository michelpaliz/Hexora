// models/client.dart
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/models/time_tracking/geofenced_visit.dart';

class GroupClient {
  String id;
  String name;
  String? pdfAlias;
  String? groupId;

  /// Optional client classification (free text, lowercase suggested)
  String? entityType;

  /// Optional property type classification (free text, lowercase suggested)
  String? propertyKind;
  String? customerType;
  String? propertyType;
  String? propertyRelationship;
  String? imageVersion;

  // Nested contact info
  String? phone;
  String? email;

  bool isActive;
  Map<String, dynamic>? meta;
  ClientBilling? billing;
  ClientServiceLocation? serviceLocation;
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
    this.pdfAlias,
    this.groupId,
    this.entityType,
    this.propertyKind,
    this.customerType,
    this.propertyType,
    this.propertyRelationship,
    this.imageVersion,
    this.phone,
    this.email,
    this.isActive = true,
    this.meta,
    this.billing,
    this.serviceLocation,
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
    String? pdfAlias,
    String? groupId,
    String? entityType,
    String? propertyKind,
    String? customerType,
    String? propertyType,
    String? propertyRelationship,
    String? imageVersion,
    String? phone,
    String? email,
    bool? isActive,
    Map<String, dynamic>? meta,
    ClientBilling? billing,
    ClientServiceLocation? serviceLocation,
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
      pdfAlias: pdfAlias ?? this.pdfAlias,
      groupId: groupId ?? this.groupId,
      entityType: entityType ?? this.entityType,
      propertyKind: propertyKind ?? this.propertyKind,
      customerType: customerType ?? this.customerType,
      propertyType: propertyType ?? this.propertyType,
      propertyRelationship: propertyRelationship ?? this.propertyRelationship,
      imageVersion: imageVersion ?? this.imageVersion,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isActive: isActive ?? this.isActive,
      meta: meta ?? this.meta,
      billing: billing ?? this.billing,
      serviceLocation: serviceLocation ?? this.serviceLocation,
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
        if (pdfAlias != null) 'pdfAlias': pdfAlias,
        'groupId': groupId,
        if (entityType != null) 'entityType': entityType,
        if (propertyKind != null) 'propertyKind': propertyKind,
        if (customerType != null) 'customerType': customerType,
        if (propertyType != null) 'propertyType': propertyType,
        if (propertyRelationship != null)
          'propertyRelationship': propertyRelationship,
        'contact': {
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        },
        'isActive': isActive,
        if (meta != null) 'meta': meta,
        if (billing != null) 'billing': billing!.toJson(),
        if (serviceLocation != null)
          'serviceLocation': serviceLocation!.toJson()
            ..remove('clientId')
            ..remove('clientName'),
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
    final serviceLocationJson =
        (json['serviceLocation'] as Map?)?.cast<String, dynamic>();
    return GroupClient(
      id: rawId,
      name: (json['name'] ?? '').toString(),
      pdfAlias: json['pdfAlias']?.toString(),
      groupId: json['groupId']?.toString(),
      entityType: json['entityType']?.toString(),
      propertyKind: json['propertyKind']?.toString(),
      customerType: json['customerType']?.toString(),
      propertyType: json['propertyType']?.toString(),
      propertyRelationship: json['propertyRelationship']?.toString(),
      imageVersion: (json['image'] as Map?)?['updatedAt']?.toString(),
      phone: contact?['phone']?.toString(),
      email: contact?['email']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
      billing: billingJson != null ? ClientBilling.fromJson(billingJson) : null,
      serviceLocation: serviceLocationJson == null
          ? null
          : ClientServiceLocation.fromJson(<String, dynamic>{
              'clientId': rawId,
              'clientName': json['name'],
              'serviceLocation': serviceLocationJson,
            }),
      hasCurrentMonthInvoice: _parseBool(
          json['hasCurrentMonthInvoice'] ?? json['has_current_month_invoice']),
      missingCurrentMonthInvoice: _parseBool(
        json['missingCurrentMonthInvoice'] ??
            json['missing_current_month_invoice'],
      ),
      currentMonthInvoiceCount: _parseInt(
        json['currentMonthInvoiceCount'] ?? json['current_month_invoice_count'],
      ),
      lastCurrentMonthInvoiceAt: _parseDate(
        json['lastCurrentMonthInvoiceAt'] ??
            json['last_current_month_invoice_at'],
      ),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
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

  /// Canonical values used by the UI while older records are being migrated.
  String? get effectiveCustomerType {
    if ((customerType ?? '').trim().isNotEmpty) return customerType;
    final value = (entityType ?? '').trim().toLowerCase();
    if (value == 'particular') return 'particular';
    if (value == 'empresa' || value == 'company') return 'company';
    if (value == 'community' ||
        value.contains('comunidad') ||
        {
          'c.prop.',
          'c.prop',
          'com. de prop.',
          'com. de prop',
          'com.de prop.',
          'com.de prop',
          'comp.de.prop.',
          'comp.de.prop',
        }.contains(value)) {
      return 'community';
    }
    return null;
  }

  String? get effectivePropertyType {
    if ((propertyType ?? '').trim().isNotEmpty) return propertyType;
    final value = (propertyKind ?? '').trim().toLowerCase();
    if (value == 'chalet') return 'chalet';
    if (value == 'hotel') return 'hotel';
    if (value == 'apartamento' || value == 'apartment') return 'apartment';
    if (value == 'edificio' || value == 'urbanizacion') return 'building';
    return null;
  }

  String? get effectivePropertyRelationship {
    if ((propertyRelationship ?? '').trim().isNotEmpty) {
      return propertyRelationship;
    }
    return [entityType, propertyKind].any(
      (value) => (value ?? '').trim().toLowerCase() == 'propietario',
    )
        ? 'owner'
        : null;
  }

  @override
  String toString() =>
      'Client{id: $id, name: $name, groupId: $groupId, customerType: $customerType, propertyType: $propertyType, propertyRelationship: $propertyRelationship, phone: $phone, email: $email, isActive: $isActive}';

  @override
  bool operator ==(Object other) =>
      other is GroupClient &&
      other.id == id &&
      other.name == name &&
      other.pdfAlias == pdfAlias &&
      other.groupId == groupId &&
      other.entityType == entityType &&
      other.propertyKind == propertyKind &&
      other.customerType == customerType &&
      other.propertyType == propertyType &&
      other.propertyRelationship == propertyRelationship;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (pdfAlias?.hashCode ?? 0) ^
      (groupId?.hashCode ?? 0) ^
      (entityType?.hashCode ?? 0) ^
      (propertyKind?.hashCode ?? 0) ^
      (customerType?.hashCode ?? 0) ^
      (propertyType?.hashCode ?? 0) ^
      (propertyRelationship?.hashCode ?? 0);
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
