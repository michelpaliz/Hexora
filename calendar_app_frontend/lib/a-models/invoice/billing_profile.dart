class BillingProfile {
  final String? id;
  final String groupId;
  final String legalName;
  final String taxId;
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
    String? id,
    String? groupId,
    String? legalName,
    String? taxId,
    String? addressStreet,
    String? addressExtra,
    String? addressCity,
    String? addressProvince,
    String? addressPostalCode,
    String? addressCountry,
    String? email,
    String? website,
    String? iban,
    String? currency,
    num? vatRate,
    String? language,
    bool? isComplete,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return BillingProfile(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      legalName: legalName ?? this.legalName,
      taxId: taxId ?? this.taxId,
      addressStreet: addressStreet ?? this.addressStreet,
      addressExtra: addressExtra ?? this.addressExtra,
      addressCity: addressCity ?? this.addressCity,
      addressProvince: addressProvince ?? this.addressProvince,
      addressPostalCode: addressPostalCode ?? this.addressPostalCode,
      addressCountry: addressCountry ?? this.addressCountry,
      email: email ?? this.email,
      website: website ?? this.website,
      iban: iban ?? this.iban,
      currency: currency ?? this.currency,
      vatRate: vatRate ?? this.vatRate,
      language: language ?? this.language,
      isComplete: isComplete ?? this.isComplete,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
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
