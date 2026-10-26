import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:intl/intl.dart';

class InvoiceChronologyConflict {
  const InvoiceChronologyConflict({
    required this.draftDate,
    required this.issuedDate,
    required this.issuedInvoiceNumber,
  });

  final DateTime draftDate;
  final DateTime issuedDate;
  final String issuedInvoiceNumber;
}

class InvoiceChronologyIssueException implements Exception {
  const InvoiceChronologyIssueException(this.conflict);
  final InvoiceChronologyConflict conflict;
}

InvoiceChronologyConflict? invoiceChronologyConflict(
  Invoice draft,
  Iterable<Invoice> issuedInvoices,
) {
  if (!draft.isDraft) return null;
  final draftDate =
      draft.issueDate ?? draft.occurrenceDate ?? draft.registeredAt;
  if (draftDate == null) return null;

  Invoice? latestInvoice;
  DateTime? latestDate;
  for (final invoice in issuedInvoices) {
    if (invoice.isDraft) continue;
    final date =
        invoice.issueDate ?? invoice.occurrenceDate ?? invoice.registeredAt;
    if (date == null || (latestDate != null && !date.isAfter(latestDate))) {
      continue;
    }
    latestInvoice = invoice;
    latestDate = date;
  }
  if (latestInvoice == null || latestDate == null) return null;

  final draftDay = DateTime(draftDate.year, draftDate.month, draftDate.day);
  final latestDay = DateTime(latestDate.year, latestDate.month, latestDate.day);
  if (!draftDay.isBefore(latestDay)) return null;

  return InvoiceChronologyConflict(
    draftDate: draftDate,
    issuedDate: latestDate,
    issuedInvoiceNumber: latestInvoice.invoiceNumber.trim(),
  );
}

/// Converts invoice-issuance failures into localized, actionable copy.
/// Raw server messages and internal document IDs must not be shown directly.
String friendlyInvoiceIssueError(
  Object error,
  AppLocalizations localizations,
) {
  if (error is InvoiceChronologyIssueException) {
    return invoiceChronologyConflictMessage(error.conflict, localizations);
  }
  final raw = error.toString().replaceFirst(RegExp(r'^\w*Exception:\s*'), '');
  final lower = raw.toLowerCase();

  final duplicate =
      (lower.contains('e11000') || lower.contains('duplicate key')) &&
          lower.contains('invoicenumber');
  if (duplicate) {
    final numberMatch = RegExp(r'invoiceNumber:\s*"([^"]+)"').firstMatch(raw) ??
        RegExp(r'invoiceNumber:\s*([^,}\s]+)').firstMatch(raw);
    final number = numberMatch?.group(1)?.trim() ?? '';
    return number.isEmpty
        ? localizations.invoiceIssueDuplicateNumberSnack
        : localizations.invoiceIssueDuplicateNumberValueSnack(number);
  }

  final chronology = RegExp(
    r'Invoice date\s+(\d{4}-\d{2}-\d{2})\s+cannot be earlier than latest issued invoice\s+(.+?)\s+dated\s+(\d{4}-\d{2}-\d{2})',
    caseSensitive: false,
  ).firstMatch(raw);
  if (chronology != null) {
    final draftDate = _localizedDate(chronology.group(1), localizations);
    final invoiceNumber = chronology.group(2)?.trim() ?? '-';
    final issuedDate = _localizedDate(chronology.group(3), localizations);
    return localizations.invoiceIssueChronologyError(
      draftDate,
      invoiceNumber,
      issuedDate,
    );
  }

  return localizations.invoiceIssueFailedSnack;
}

String invoiceChronologyConflictMessage(
  InvoiceChronologyConflict conflict,
  AppLocalizations localizations,
) =>
    localizations.invoiceIssueChronologyError(
      DateFormat.yMMMd(localizations.localeName).format(conflict.draftDate),
      conflict.issuedInvoiceNumber.isEmpty ? '-' : conflict.issuedInvoiceNumber,
      DateFormat.yMMMd(localizations.localeName).format(conflict.issuedDate),
    );

String _localizedDate(String? value, AppLocalizations localizations) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) return value ?? '-';
  return DateFormat.yMMMd(localizations.localeName).format(parsed);
}
