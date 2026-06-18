class StatementExpenseSuggestion {
  final String id;
  final String expenseNumber;
  final String providerId;
  final String providerName;
  final String status;
  final DateTime? issueDate;
  final double? total;
  final String currency;
  final bool alreadyLinked;
  final int linkedEntriesCount;
  final String? linkedEntryId;
  final DateTime? linkedEntryDate;
  final double? linkedEntryAmount;
  final String? linkedEntryDescription;
  final double? score;
  final List<String> matchReasons;

  const StatementExpenseSuggestion({
    required this.id,
    required this.expenseNumber,
    required this.providerId,
    required this.providerName,
    required this.status,
    required this.issueDate,
    required this.total,
    required this.currency,
    required this.alreadyLinked,
    required this.linkedEntriesCount,
    required this.linkedEntryId,
    required this.linkedEntryDate,
    required this.linkedEntryAmount,
    required this.linkedEntryDescription,
    required this.score,
    required this.matchReasons,
  });

  factory StatementExpenseSuggestion.fromJson(Map<String, dynamic> json) {
    final rawId = (json['id'] ?? json['_id'] ?? json['expenseId'] ?? '')
        .toString()
        .trim();
    return StatementExpenseSuggestion(
      id: rawId,
      expenseNumber: (json['expenseNumber'] ??
              json['invoiceNumber'] ??
              json['number'] ??
              rawId)
          .toString()
          .trim(),
      providerId:
          (json['providerId'] ?? json['provider_id'] ?? '').toString().trim(),
      providerName: (json['providerName'] ??
              json['provider_name'] ??
              json['vendorName'] ??
              json['vendor_name'] ??
              json['vendor'] ??
              '')
          .toString()
          .trim(),
      status: (json['status'] ?? '').toString().trim(),
      issueDate: _parseDate(json['issueDate'] ?? json['issue_date']),
      total: _parseDouble(json['total']),
      currency: (json['currency'] ?? '').toString().trim(),
      alreadyLinked:
          json['alreadyLinked'] == true || json['isAlreadyLinked'] == true,
      linkedEntriesCount: _parseInt(
            json['linkedEntriesCount'] ?? json['linked_entries_count'],
          ) ??
          0,
      linkedEntryId:
          (json['linkedEntryId'] ?? json['linked_entry_id'])?.toString().trim(),
      linkedEntryDate:
          _parseDate(json['linkedEntryDate'] ?? json['linked_entry_date']),
      linkedEntryAmount: _parseDouble(
        json['linkedEntryAmount'] ?? json['linked_entry_amount'],
      ),
      linkedEntryDescription:
          (json['linkedEntryDescription'] ?? json['linked_entry_description'])
              ?.toString()
              .trim(),
      score: _parseDouble(json['score']),
      matchReasons: _parseStringList(json['matchReasons'] ?? json['match_reasons']),
    );
  }

  String get displayNumber => expenseNumber.isEmpty ? id : expenseNumber;
  String get displayProviderName => providerName.isEmpty ? '-' : providerName;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim());
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

List<String> _parseStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
