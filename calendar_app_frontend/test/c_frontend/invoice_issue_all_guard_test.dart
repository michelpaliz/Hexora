import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/a-models/invoice/invoice.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/invoices/group_invoce_flow/screens/group_invoices/widgets/invoices_flow_view.dart';
import 'package:hexora/f-themes/font_type/typography_extension.dart';
import 'package:hexora/l10n/app_localizations.dart';

const _typography = AppTypography(
  displayLarge: TextStyle(),
  displayMedium: TextStyle(),
  titleLarge: TextStyle(),
  bodyLarge: TextStyle(),
  bodyMedium: TextStyle(),
  bodySmall: TextStyle(),
  buttonText: TextStyle(),
  caption: TextStyle(),
  accentHeading: TextStyle(),
  accentText: TextStyle(),
);

void main() {
  testWidgets('rapid taps trigger one batch issuance callback', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final operation = Completer<void>();
    var calls = 0;
    const draft = Invoice(
      id: 'invoice-1',
      invoiceNumber: '',
      groupId: 'group-1',
      clientId: 'client-1',
      status: 'draft',
    );
    final client = GroupClient(
      id: 'client-1',
      name: 'Client',
      isActive: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        theme: ThemeData(extensions: const [_typography]),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InvoicesView(
            typography: _typography,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            drafts: const [draft],
            invoices: const [],
            clients: [client],
            selectedInvoice: draft,
            onSelectInvoice: (_) {},
            onDeleteDraft: (_) {},
            onEditDraft: (_) {},
            detailBuilder: (_) => const SizedBox.shrink(),
            invoiceItemBuilder: (
              invoice,
              client, {
              onDelete,
              onEdit,
              required onTap,
            }) =>
                ListTile(title: Text(invoice.id), onTap: onTap),
            onIssueAll: (_) async {
              calls++;
              await operation.future;
            },
          ),
        ),
      ),
    );

    final issueAllButton = find.text('Issue all');
    expect(issueAllButton, findsOneWidget);

    final issueAllGesture = find.ancestor(
      of: issueAllButton,
      matching: find.byType(GestureDetector),
    );
    expect(issueAllGesture, findsOneWidget);
    final onTap = tester.widget<GestureDetector>(issueAllGesture).onTap!;
    onTap();
    onTap();
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);

    final confirmButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Issue all'),
    );
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.pump();

    expect(calls, 1);

    operation.complete();
    await tester.pumpAndSettle();
  });
}
