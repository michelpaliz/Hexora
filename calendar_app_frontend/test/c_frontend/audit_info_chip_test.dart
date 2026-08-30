import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/audit_info_chip.dart';

void main() {
  testWidgets('renders the supplied metadata icon and value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditInfoChip(
            icon: Icons.calendar_today_outlined,
            value: '2026-08-30',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    expect(find.text('2026-08-30'), findsOneWidget);
  });
}
