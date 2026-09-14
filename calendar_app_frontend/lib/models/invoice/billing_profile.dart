class BillingProfile {
  static const Object _unset = Object();

  final String? id;
  final String groupId;
  final String legalName;
  final String taxId;
  final String? logoUrl;
  final String? addressStreet;
  final String? addressExtra;
  final String? addressCity;
  final String? addressProvince;
  final String? addressPostalCode;
  final String? addressCountry;
  final String? email;
  final String? website;
  final String? iban;
  final String currency;
  final num vatRate;
  final String? language;
  final bool? isComplete;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const BillingProfile({
    this.id,
    required this.groupId,
    required this.legalName,
    required this.taxId,
    this.logoUrl,
    this.addressStreet,
    this.addressExtra,
    this.addressCity,
    this.addressProvince,
    this.addressPostalCode,
    this.addressCountry,
    this.email,
    this.website,
    this.iban,
    this.currency = 'EUR',
    this.vatRate = 21,
    this.language,
    this.isComplete,
    this.updatedAt,
    this.createdAt,
  });

  BillingProfile copyWith({
    Object? id = _unset,
    String? groupId,
    String? legalName,
    String? taxId,
    Object? logoUrl = _unset,
    Object? addressStreet = _unset,
    Object? addressExtra = _unset,
    Object? addressCity = _unset,
    Object? addressProvince = _unset,
    Object? addressPostalCode = _unset,
    Object? addressCountry = _unset,
    Object? email = _unset,
    Object? website = _unset,
    Object? iban = _unset,
    String? currency,
    num? vatRate,
    Object? language = _unset,
    Object? isComplete = _unset,
    Object? updatedAt = _unset,
    Object? createdAt = _unset,
  }) {
    return BillingProfile(
      id: identical(id, _unset) ? this.id : id as String?,
      groupId: groupId ?? this.groupId,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      logoUrl: identical(logoUrl, _unset) ? this.logoUrl : logoUrl as String?,
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
      website: identical(website, _unset) ? this.website : website as String?,
      iban: identical(iban, _unset) ? this.iban : iban as String?,
      currency: currency ?? this.currency,
      vatRate: vatRate ?? this.vatRate,
      language:
          identical(language, _unset) ? this.language : language as String?,
      isComplete: identical(isComplete, _unset)
          ? this.isComplete
          : isComplete as bool?,
      updatedAt: identical(updatedAt, _unset)
          ? this.updatedAt
          : updatedAt as DateTime?,
      createdAt: identical(createdAt, _unset)
          ? this.createdAt
          : createdAt as DateTime?,
    );
  }

  factory BillingProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    return BillingProfile(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      groupId: (json['groupId'] ?? '').toString(),
      legalName: (json['legalName'] ?? '').toString(),
      taxId: (json['taxId'] ?? '').toString(),
      logoUrl: json['logoUrl']?.toString(),
      addressStreet: json['addressStreet']?.toString(),
      addressExtra: json['addressExtra']?.toString(),
      addressCity: json['addressCity']?.toString(),
      addressProvince: json['addressProvince']?.toString(),
      addressPostalCode: json['addressPostalCode']?.toString(),
      addressCountry: json['addressCountry']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      iban: json['iban']?.toString(),
      currency: (json['currency'] ?? 'EUR').toString(),
      vatRate: json['vatRate'] is num ? json['vatRate'] as num : 21,
      language: json['language']?.toString(),
      isComplete:
          json['isComplete'] is bool ? json['isComplete'] as bool : null,
      updatedAt: parseDate(json['updatedAt']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'groupId': groupId,
        'legalName': legalName,
        'taxId': taxId,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (addressStreet != null) 'addressStreet': addressStreet,
        if (addressExtra != null) 'addressExtra': addressExtra,
        if (addressCity != null) 'addressCity': addressCity,
        if (addressProvince != null) 'addressProvince': addressProvince,
        if (addressPostalCode != null) 'addressPostalCode': addressPostalCode,
        if (addressCountry != null) 'addressCountry': addressCountry,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (iban != null) 'iban': iban,
        'currency': currency,
        'vatRate': vatRate,
        if (language != null) 'language': language,
        if (isComplete != null) 'isComplete': isComplete,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  Map<String, dynamic> toPayload() {
    String? clean(String? v) => v?.trim().isEmpty ?? true ? null : v?.trim();
    return {
      'groupId': groupId,
      'legalName': clean(legalName) ?? '',
      'taxId': clean(taxId) ?? '',
      'logoUrl': clean(logoUrl),
      'addressStreet': clean(addressStreet),
      'addressExtra': clean(addressExtra),
      'addressCity': clean(addressCity),
      'addressProvince': clean(addressProvince),
      'addressPostalCode': clean(addressPostalCode),
      'addressCountry': clean(addressCountry),
      'email': clean(email),
      'website': clean(website),
      'iban': clean(iban),
      'currency': clean(currency) ?? 'EUR',
      'vatRate': vatRate,
      'language': clean(language),
    };
  }
}
