class ClientInvoiceStats {
  final String clientId;
  final String clientName;
  final ClientInvoiceStatsRange range;
  final List<ClientInvoiceStatsMonth> months;
  final ClientInvoiceStatsSummary summary;

  const ClientInvoiceStats({
    required this.clientId,
    required this.clientName,
    required this.range,
    required this.months,
    required this.summary,
  });

  factory ClientInvoiceStats.fromJson(Map<String, dynamic> json) {
    final rawMonths = json['months'];
    return ClientInvoiceStats(
      clientId: (json['clientId'] ?? '').toString(),
      clientName: (json['clientName'] ?? '').toString(),
      range: ClientInvoiceStatsRange.fromJson(
        (json['range'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      months: rawMonths is List
          ? rawMonths
              .whereType<Map>()
              .map(
                (item) => ClientInvoiceStatsMonth.fromJson(
                  item.cast<String, dynamic>(),
                ),
              )
              .toList(growable: false)
          : const [],
      summary: ClientInvoiceStatsSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  bool get hasAnyMonthlyActivity => months.any(
        (month) =>
            month.issuedCount > 0 ||
            month.issuedTotal > 0 ||
            month.draftCount > 0 ||
            month.draftTotal > 0 ||
            month.voidCount > 0 ||
            month.voidTotal > 0,
      );
}

class ClientInvoiceStatsRange {
  final int months;
  final DateTime? from;
  final DateTime? to;

  const ClientInvoiceStatsRange({
    required this.months,
    required this.from,
    required this.to,
  });

  factory ClientInvoiceStatsRange.fromJson(Map<String, dynamic> json) {
    return ClientInvoiceStatsRange(
      months: _parseInt(json['months']) ?? 12,
      from: _parseDate(json['from']),
      to: _parseDate(json['to']),
    );
  }
}

class ClientInvoiceStatsMonth {
  final String month;
  final int issuedCount;
  final double issuedTotal;
  final int draftCount;
  final double draftTotal;
  final int voidCount;
  final double voidTotal;

  const ClientInvoiceStatsMonth({
    required this.month,
    required this.issuedCount,
    required this.issuedTotal,
    required this.draftCount,
    required this.draftTotal,
    required this.voidCount,
    required this.voidTotal,
  });

  factory ClientInvoiceStatsMonth.fromJson(Map<String, dynamic> json) {
    return ClientInvoiceStatsMonth(
      month: (json['month'] ?? '').toString(),
      issuedCount: _parseInt(json['issuedCount']) ?? 0,
      issuedTotal: _parseDouble(json['issuedTotal']) ?? 0,
      draftCount: _parseInt(json['draftCount']) ?? 0,
      draftTotal: _parseDouble(json['draftTotal']) ?? 0,
      voidCount: _parseInt(json['voidCount']) ?? 0,
      voidTotal: _parseDouble(json['voidTotal']) ?? 0,
    );
  }
}

class ClientInvoiceStatsSummary {
  final int totalInvoices;
  final int issuedCount;
  final double issuedTotal;
  final int draftCount;
  final double draftTotal;
  final int voidCount;
  final double voidTotal;
  final DateTime? lastIssuedAt;

  const ClientInvoiceStatsSummary({
    required this.totalInvoices,
    required this.issuedCount,
    required this.issuedTotal,
    required this.draftCount,
    required this.draftTotal,
    required this.voidCount,
    required this.voidTotal,
    required this.lastIssuedAt,
  });

  factory ClientInvoiceStatsSummary.fromJson(Map<String, dynamic> json) {
    return ClientInvoiceStatsSummary(
      totalInvoices: _parseInt(json['totalInvoices']) ?? 0,
      issuedCount: _parseInt(json['issuedCount']) ?? 0,
      issuedTotal: _parseDouble(json['issuedTotal']) ?? 0,
      draftCount: _parseInt(json['draftCount']) ?? 0,
      draftTotal: _parseDouble(json['draftTotal']) ?? 0,
      voidCount: _parseInt(json['voidCount']) ?? 0,
      voidTotal: _parseDouble(json['voidTotal']) ?? 0,
      lastIssuedAt: _parseDate(json['lastIssuedAt']),
    );
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final raw = value.toString().trim();
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
