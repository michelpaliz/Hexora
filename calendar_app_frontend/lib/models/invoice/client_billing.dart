class ClientBilling {
  static const Object _unset = Object();

  final String? legalName;
  final String? taxId;
  final String? addressStreet;
  final String? addressExtra;
  final String? addressCity;
  final String? addressProvince;
  final String? addressPostalCode;
  final String? addressCountry;
  final String? email;
  final String? phone;
  final bool? isComplete;
  final String? documentType; // invoice | receipt
  final DateTime? updatedAt;

  const ClientBilling({
    this.legalName,
    this.taxId,
    this.addressStreet,
    this.addressExtra,
    this.addressCity,
    this.addressProvince,
    this.addressPostalCode,
    this.addressCountry,
    this.email,
    this.phone,
    this.isComplete,
    this.documentType,
    this.updatedAt,
  });

  ClientBilling copyWith({
    Object? legalName = _unset,
    Object? taxId = _unset,
    Object? addressStreet = _unset,
    Object? addressExtra = _unset,
    Object? addressCity = _unset,
    Object? addressProvince = _unset,
    Object? addressPostalCode = _unset,
    Object? addressCountry = _unset,
    Object? email = _unset,
    Object? phone = _unset,
    Object? isComplete = _unset,
    Object? documentType = _unset,
    Object? updatedAt = _unset,
  }) {
    return ClientBilling(
      legalName: identical(legalName, _unset)
          ? this.legalName
          : legalName as String?,
      taxId: identical(taxId, _unset) ? this.taxId : taxId as String?,
      addressStreet: identical(addressStreet, _unset)
          ? this.addressStreet
          : addressStreet as String?,
      addressExtra: identical(addressExtra, _unset)
          ? this.addressExtra
          : addressExtra as String?,
      addressCity: identical(addressCity, _unset)
          ? this.addressCity
          : addressCity as String?,
      addressProvince: identical(addressProvince, _unset)
          ? this.addressProvince
          : addressProvince as String?,
      addressPostalCode: identical(addressPostalCode, _unset)
          ? this.addressPostalCode
          : addressPostalCode as String?,
      addressCountry: identical(addressCountry, _unset)
          ? this.addressCountry
          : addressCountry as String?,
      email: identical(email, _unset) ? this.email : email as String?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      isComplete: identical(isComplete, _unset)
          ? this.isComplete
          : isComplete as bool?,
      documentType: identical(documentType, _unset)
          ? this.documentType
          : documentType as String?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
    );
  }

  factory ClientBilling.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return ClientBilling(
      legalName: json['legalName']?.toString(),
      taxId: json['taxId']?.toString(),
      addressStreet: json['addressStreet']?.toString(),
      addressExtra: json['addressExtra']?.toString(),
      addressCity: json['addressCity']?.toString(),
      addressProvince: json['addressProvince']?.toString(),
      addressPostalCode: json['addressPostalCode']?.toString(),
      addressCountry: json['addressCountry']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      isComplete:
          json['isComplete'] is bool ? json['isComplete'] as bool : null,
      documentType: json['documentType']?.toString(),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (legalName != null) 'legalName': legalName,
        if (taxId != null) 'taxId': taxId,
        if (addressStreet != null) 'addressStreet': addressStreet,
        if (addressExtra != null) 'addressExtra': addressExtra,
        if (addressCity != null) 'addressCity': addressCity,
        if (addressProvince != null) 'addressProvince': addressProvince,
        if (addressPostalCode != null) 'addressPostalCode': addressPostalCode,
        if (addressCountry != null) 'addressCountry': addressCountry,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (isComplete != null) 'isComplete': isComplete,
        if (documentType != null) 'documentType': documentType,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  /// Payload helper for create/update; excludes read-only flags.
  Map<String, dynamic>? toPayload({bool includeNulls = false}) {
    String? clean(String? v) => v?.trim().isEmpty ?? true ? null : v?.trim();
    final payload = <String, dynamic>{
      if (includeNulls || clean(legalName) != null)
        'legalName': clean(legalName),
      if (includeNulls || clean(taxId) != null) 'taxId': clean(taxId),
      if (includeNulls || clean(addressStreet) != null)
        'addressStreet': clean(addressStreet),
      if (includeNulls || clean(addressExtra) != null)
        'addressExtra': clean(addressExtra),
      if (includeNulls || clean(addressCity) != null)
        'addressCity': clean(addressCity),
      if (includeNulls || clean(addressProvince) != null)
        'addressProvince': clean(addressProvince),
      if (includeNulls || clean(addressPostalCode) != null)
        'addressPostalCode': clean(addressPostalCode),
      if (includeNulls || clean(addressCountry) != null)
        'addressCountry': clean(addressCountry),
      if (includeNulls || clean(email) != null) 'email': clean(email),
      if (includeNulls || clean(phone) != null) 'phone': clean(phone),
      if (includeNulls || documentType != null)
        'documentType': documentType ?? 'invoice',
    };

    final filtered = Map<String, dynamic>.fromEntries(
      payload.entries.where((e) => includeNulls || e.value != null),
    );
    return filtered.isEmpty ? null : filtered;
  }

  bool get hasData =>
      toPayload()?.values.any((_) => true) ??
      false; // any non-null value after cleaning
}
