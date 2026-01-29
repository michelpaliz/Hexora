class MailAddress {
  final String address;
  final String? name;

  const MailAddress({required this.address, this.name});

  String get display {
    final label = name?.trim();
    if (label != null && label.isNotEmpty) {
      return '$label <$address>';
    }
    return address;
  }

  static MailAddress? parse(dynamic v) {
    if (v == null) return null;
    if (v is MailAddress) return v;
    if (v is String) {
      final trimmed = v.trim();
      if (trimmed.isEmpty) return null;
      final match = RegExp(r'^(.*)<([^>]+)>$').firstMatch(trimmed);
      if (match != null) {
        final rawName = match.group(1)?.trim();
        final email = match.group(2)?.trim();
        if (email == null || email.isEmpty) return null;
        final cleanedName = rawName == null
            ? null
            : rawName.replaceAll(RegExp("^[\"']|[\"']\$"), '').trim();
        return MailAddress(
          address: email,
          name: (cleanedName == null || cleanedName.isEmpty)
              ? null
              : cleanedName,
        );
      }
      return MailAddress(address: trimmed);
    }
    if (v is Map) {
      final map = v.cast<String, dynamic>();
      final addr = map['address'] ??
          map['email'] ??
          map['value'] ??
          map['from_address'] ??
          map['from'] ??
          map['to'];
      if (addr == null) return null;
      final rawName = map['name'] ?? map['displayName'] ?? map['display_name'];
      return MailAddress(
        address: addr.toString(),
        name: rawName?.toString(),
      );
    }
    return MailAddress(address: v.toString());
  }

  static List<MailAddress> parseList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map(parse).whereType<MailAddress>().toList();
    }
    final single = parse(v);
    return single == null ? const [] : [single];
  }

  Map<String, dynamic> toJson() {
    final cleanedName = name?.trim();
    return {
      'address': address,
      if (cleanedName != null && cleanedName.isNotEmpty) 'name': cleanedName,
    };
  }
}
