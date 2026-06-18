class StatementEntry {
  final Map<String, dynamic> raw;
  const StatementEntry(this.raw);

  String get id => (raw['_id'] ?? raw['id'] ?? raw['entryId'] ?? '').toString();
}

class StatementEntriesTiming {
  final int? dbMs;
  final int? totalMs;
  const StatementEntriesTiming({this.dbMs, this.totalMs});
}

class StatementEntriesPage {
  final List<StatementEntry> items;
  final int page;
  final int size;
  final int total;
  final int totalPages;
  final String? nextCursor;
  final StatementEntriesTiming? timing;

  const StatementEntriesPage({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.totalPages,
    required this.nextCursor,
    required this.timing,
  });
}
