import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/audit/audit_section_label.dart';

void main() {
  testWidgets('renders the section label in uppercase', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuditSectionLabel(label: 'Amount comparison'),
        ),
      ),
    );

    expect(find.text('AMOUNT COMPARISON'), findsOneWidget);
  });
}
