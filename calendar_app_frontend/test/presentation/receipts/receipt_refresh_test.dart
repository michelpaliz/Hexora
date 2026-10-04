import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/receipt/receipt.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/views/group_receipts_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/receipt_editor_wizard_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> receiptJson(num current) => {
      '_id': 'receipt',
      'groupId': 'group',
      'clientId': 'client',
      'status': 'draft',
      'total': 302,
      'subtotal': 302,
      'totals': {'total': current, 'subtotal': current},
      'lines': [
        {
          'description': 'Limpieza',
          'quantity': 10,
          'unitPrice': current / 10,
          'lineTotal': current
        }
      ],
    };
void main() {
  test('receipt prefers recalculated totals including zero and numeric strings',
      () {
    expect(Receipt.fromJson(receiptJson(120.8)).total, 120.8);
    expect(Receipt.fromJson(receiptJson(120.8)).subtotal, 120.8);
    expect(Receipt.fromJson(receiptJson(0)).total, 0);
    expect(
        Receipt.fromJson({
          ...receiptJson(302),
          'totals': {'total': '120.80'}
        }).total,
        120.8);
  });
  test(
      'receipt preserves legacy totals when nested totals are absent or invalid',
      () {
    expect(Receipt.fromJson({'total': 302, 'subtotal': 302}).total, 302);
    expect(Receipt.fromJson({'total': '120.80'}).total, 120.8);
    expect(
        Receipt.fromJson({
          'total': 302,
          'totals': {'total': 'invalid'}
        }).total,
        302);
    expect(Receipt.fromJson({}).total, isNull);
  });
  testWidgets('returning from receipt edit refreshes list and selected detail',
      (tester) async {
    tester.view.physicalSize = const Size(2400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    TokenService.configureStore(_Tokens());
    addTearDown(() => TokenService.configureStore(SecureTokenStore()));
    var current = 302.0;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: GroupInvoicesScreen(
          group: Group(
              id: 'group',
              name: 'Team',
              ownerId: 'owner',
              userRoles: {},
              userIds: [],
              createdTime: DateTime(2026),
              description: ''),
          initialMenu: 'receipts',
          embedded: true,
        )),
      ));
      await tester.pumpAndSettle();
      GroupReceiptsView view() =>
          tester.widget<GroupReceiptsView>(find.byType(GroupReceiptsView));
      expect(view().selectedReceipt!.total, 302);
      view().onEditReceipt(view().selectedReceipt!);
      await tester.pumpAndSettle();
      current = 120.8;
      Navigator.of(tester.element(find.byType(ReceiptEditorWizardScreen)))
          .pop(true);
      await tester.pumpAndSettle();
      expect(view().drafts.single.total, 120.8);
      expect(view().selectedReceipt!.total, 120.8);
      expect(identical(view().selectedReceipt, view().drafts.single), isTrue);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              final path = request.url.path;
              Object payload = [];
              if (path.contains('billing') || path.contains('/pdf')) {
                return http.Response('{}', 404);
              }
              if (path.endsWith('/clients')) {
                payload = [
                  {
                    '_id': 'client',
                    'name': 'Las Alondras Playa',
                    'isActive': true
                  }
                ];
              }
              if (path.endsWith('/receipts')) {
                payload = request.url.queryParameters['status'] == 'draft'
                    ? [receiptJson(current)]
                    : [];
              }
              if (path.endsWith('/draft/unnumbered')) {
                payload = {'exists': false};
              }
              if (path.endsWith('/receipts/receipt')) {
                payload = receiptJson(current);
              }
              return http.Response(jsonEncode(payload), 200,
                  headers: {'content-type': 'application/json'});
            }));
  });
}
