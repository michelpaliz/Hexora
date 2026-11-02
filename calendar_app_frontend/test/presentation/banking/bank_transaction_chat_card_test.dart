import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/business_chat/bank_transaction_chat_card.dart';

void main() {
  testWidgets('shared transaction shows its current status and opens the source', (tester) async {
    var opened = false;
    var reviewed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BankTransactionChatCard(
      transaction: const {
        'entryId': 'entry-1', 'description': 'Ingreso desconocido', 'amount': 125,
        'date': '2026-10-28T00:00:00.000Z', 'status': 'linked', 'available': true,
        'linkedDocuments': [{'type': 'invoice', 'number': '398-26', 'counterparty': 'Residencial El Sol', 'total': 125, 'available': true}],
      },
      onOpen: () => opened = true,
      onReview: () => reviewed = true,
    ))));
    expect(find.text('Ingreso desconocido'), findsOneWidget);
    expect(find.textContaining('Vinculado'), findsOneWidget);
    expect(find.textContaining('398-26'), findsOneWidget);
    await tester.tap(find.text('Revisar vínculo'));
    expect(reviewed, isTrue);
    await tester.tap(find.text('Ver movimiento'));
    expect(opened, isTrue);
  });

  testWidgets('removed transaction keeps its snapshot but cannot be opened', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BankTransactionChatCard(
      transaction: {
        'entryId': 'entry-1', 'description': 'Ingreso desconocido', 'amount': 125,
        'status': 'unavailable', 'available': false,
      },
      onOpen: null,
    ))));
    expect(find.text('Ingreso desconocido'), findsOneWidget);
    expect(find.textContaining('No disponible'), findsOneWidget);
    expect(find.text('Ver movimiento'), findsNothing);
  });

  testWidgets('restricted viewer sees no financial data', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BankTransactionChatCard(
      transaction: {'restricted': true}, onOpen: null,
    ))));
    expect(find.textContaining('acceso restringido'), findsOneWidget);
    expect(find.text('Ver movimiento'), findsNothing);
  });
}
