import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations_en.dart';
import 'package:hexora/l10n/app_localizations_es.dart';
import 'package:hexora/models/invoice/invoice.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/shared/invoice_issue_error_message.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  const chronologyError =
      'Invoice date 2026-10-24 cannot be earlier than latest issued invoice 382-26 dated 2026-10-26';

  test('invoice chronology error is user-facing in Spanish', () {
    final message = friendlyInvoiceIssueError(
      Exception(chronologyError),
      AppLocalizationsEs(),
    );

    expect(message, contains('24 oct 2026'));
    expect(message, contains('382-26'));
    expect(message, contains('26 oct 2026'));
    expect(message, contains('ya se emitió'));
    expect(message, isNot(contains('Invoice date')));
    expect(message, isNot(contains('cannot be earlier')));
  });

  test('invoice chronology error is user-facing in English', () {
    final message = friendlyInvoiceIssueError(
      Exception(chronologyError),
      AppLocalizationsEn(),
    );

    expect(message, contains('Oct 24, 2026'));
    expect(message, contains('382-26'));
    expect(message, contains('Oct 26, 2026'));
    expect(message, contains('Change the draft date'));
    expect(message, isNot(contains('cannot be earlier')));
  });

  test('unknown technical errors use the safe localized fallback', () {
    const raw = 'CastError: internalId=6adcc8d04ce65ab30038e744';

    expect(
      friendlyInvoiceIssueError(Exception(raw), AppLocalizationsEs()),
      AppLocalizationsEs().invoiceIssueFailedSnack,
    );
    expect(
      friendlyInvoiceIssueError(Exception(raw), AppLocalizationsEn()),
      AppLocalizationsEn().invoiceIssueFailedSnack,
    );
  });

  test('chronology warning uses the same calendar-day rule as issuance', () {
    final issued = Invoice(
      id: 'issued',
      invoiceNumber: '382-26',
      groupId: 'group',
      clientId: 'client',
      status: 'issued',
      issueDate: DateTime(2026, 10, 26),
    );
    final invalidDraft = Invoice(
      id: 'draft',
      invoiceNumber: '',
      groupId: 'group',
      clientId: 'client',
      status: 'draft',
      issueDate: DateTime(2026, 10, 24),
    );
    final validDraft = invalidDraft.copyWith(
      issueDate: DateTime(2026, 10, 26),
    );

    final conflict = invoiceChronologyConflict(invalidDraft, [issued]);
    expect(conflict, isNotNull);
    expect(conflict!.issuedInvoiceNumber, '382-26');
    expect(invoiceChronologyConflict(validDraft, [issued]), isNull);
  });
}
