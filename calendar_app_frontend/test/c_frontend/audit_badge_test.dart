import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoices/widgets/audit_badge.dart';

void main() {
  testWidgets('renders the audit status with its supplied color',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditBadge(
            label: 'Confirmed',
            color: Colors.green,
            textStyle: TextStyle(),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Confirmed'));
    expect(text.style?.color, Colors.green);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.fontSize, 11);
  });
}
