import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/utils/audit_presentation_utils.dart';

String _spanish(String spanish, String english) => spanish;
String _english(String spanish, String english) => english;

void main() {
  test('maps review statuses in the selected language', () {
    expect(auditReviewLabel('confirmed_ok', _spanish), 'Confirmado');
    expect(auditReviewLabel('needs_fix', _english), 'Needs fix');
    expect(auditReviewLabel('unknown', _english), 'Unreviewed');
  });

  test('maps reason codes case-insensitively and preserves unknown codes', () {
    expect(
      auditReasonLabel('tax_total_mismatch', _spanish),
      'Discrepancia en IVA',
    );
    expect(auditReasonLabel('CUSTOM_REASON', _english), 'CUSTOM_REASON');
  });

  test('prioritizes suspect and confirmed status colors', () {
    const colors = ColorScheme.light(
      error: Colors.red,
      tertiary: Colors.green,
      onSurfaceVariant: Colors.grey,
    );

    expect(auditStatusColor(true, 'confirmed_ok', colors), Colors.red);
    expect(auditStatusColor(false, 'confirmed_ok', colors), Colors.green);
    expect(auditStatusColor(false, 'unreviewed', colors), Colors.grey);
  });
}
