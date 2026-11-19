/// Shared invoice-number matching for the list filters.
String normalizeInvoiceNumberSearch(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool invoiceNumberMatchesSearch(String invoiceNumber, String query) {
  final rawQuery = query.trim().toLowerCase();
  if (rawQuery.isEmpty) return true;
  final rawNumber = invoiceNumber.trim().toLowerCase();
  final normalizedQuery = normalizeInvoiceNumberSearch(rawQuery);
  return rawNumber.contains(rawQuery) ||
      (normalizedQuery.isNotEmpty &&
          normalizeInvoiceNumberSearch(rawNumber).contains(normalizedQuery));
}
