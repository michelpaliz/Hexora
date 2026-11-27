import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/hexora_empty_state.dart';

void main() {
  testWidgets('renders copy and optional actions', (tester) async {
    var primaryPressed = false;
    var secondaryPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HexoraEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No invoices yet',
            description: 'Create your first invoice to get started.',
            primaryAction: HexoraEmptyStateAction(
              label: 'Create invoice',
              onPressed: () => primaryPressed = true,
            ),
            secondaryAction: HexoraEmptyStateAction(
              label: 'Learn more',
              onPressed: () => secondaryPressed = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('No invoices yet'), findsOneWidget);
    expect(
        find.text('Create your first invoice to get started.'), findsOneWidget);
    await tester.tap(find.text('Create invoice'));
    await tester.tap(find.text('Learn more'));
    expect(primaryPressed, isTrue);
    expect(secondaryPressed, isTrue);
  });

  testWidgets('compact variant stays content sized', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              HexoraEmptyState(
                icon: Icons.history_rounded,
                title: 'No changes yet',
                description: 'Changes will appear here.',
                variant: HexoraEmptyStateVariant.compact,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FilledButton), findsNothing);
  });
}
