import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/invoice/client_billing.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/receipt_editor_wizard_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('receipt restores all optional manual client fields',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ReceiptEditorWizardScreen(
        group: Group(
          id: 'group-1',
          name: 'Hexora',
          ownerId: 'owner-1',
          userRoles: const {},
          userIds: const [],
          createdTime: DateTime(2026),
          description: '',
        ),
        clients: const [],
        initialReceipt: const Receipt(
          id: 'receipt-1',
          groupId: 'group-1',
          clientId: '',
          clientName: 'Cliente temporal',
          status: 'draft',
          clientSnapshot: ClientBilling(
            legalName: 'Cliente temporal',
            addressStreet: 'Calle Mar 1',
            addressCity: 'Almería',
            addressPostalCode: '04001',
            documentType: 'receipt',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receipt-editor-step-0')));
    await tester.pumpAndSettle();

    expect(find.text('Cliente temporal'), findsOneWidget);
    expect(find.text('Calle Mar 1'), findsOneWidget);
    expect(find.text('Almería'), findsOneWidget);
    expect(find.text('04001'), findsOneWidget);
    expect(find.text('Dirección'), findsOneWidget);
    expect(find.text('Ciudad'), findsOneWidget);
    expect(find.text('CP'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
