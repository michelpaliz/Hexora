import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/audit_format_utils.dart';

void main() {
  group('formatAuditQueryDate', () {
    test('formats dates for API query parameters', () {
      expect(formatAuditQueryDate(DateTime(2026, 8, 3)), '2026-08-03');
    });

    test('keeps an unset filter nullable', () {
      expect(formatAuditQueryDate(null), isNull);
    });
  });

  group('formatAuditDate', () {
    test('keeps the date portion of timestamp values', () {
      expect(formatAuditDate('2026-08-30T12:45:00Z'), '2026-08-30');
      expect(formatAuditDate('2026-08'), '2026-08');
    });

    test('uses an em dash for missing values', () {
      expect(formatAuditDate(null), '—');
      expect(formatAuditDate('  '), '—');
    });
  });

  group('formatAuditMoney', () {
    test('formats numeric values with EU separators and two decimals', () {
      expect(formatAuditMoney(1234.5), '1.234,50');
      expect(formatAuditMoney('-1234.5'), '-1.234,50');
    });

    test('uses an em dash for missing or invalid values', () {
      expect(formatAuditMoney(null), '—');
      expect(formatAuditMoney('not-a-number'), '—');
    });
  });
}
