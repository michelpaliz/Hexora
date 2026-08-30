import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/audit_date_field.dart';

void main() {
  testWidgets('shows its label and selected date', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuditDateField(
            label: 'From',
            value: '2026-08-30',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('From'), findsOneWidget);
    expect(find.text('2026-08-30'), findsOneWidget);
  });

  testWidgets('shows the fallback and forwards taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AuditDateField(
            label: 'To',
            value: null,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.byType(AuditDateField));
    expect(tapped, isTrue);
  });
}
