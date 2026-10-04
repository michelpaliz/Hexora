import 'package:flutter/material.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/group_invoices_side_menu.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices_screen.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/recurring_invoices/recurring_invoices_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final removeParent in [false, true]) {
    testWidgets('recurring cleanup is safe (remove parent: $removeParent)',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TokenService.configureStore(_Tokens());
      addTearDown(() => TokenService.configureStore(SecureTokenStore()));
      await http.runWithClient(() async {
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.fromBrightness(Brightness.light),
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
            initialMenu: 'recurring',
            embedded: true,
          )),
        ));
        await tester.pumpAndSettle();
        expect(find.byType(RecurringInvoicesScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (removeParent) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          tester
              .widget<GroupInvoicesSideMenu>(find.byType(GroupInvoicesSideMenu))
              .onMenuChanged('invoices');
          await tester.pumpAndSettle();
          expect(find.byType(RecurringInvoicesScreen), findsNothing);
        }
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
          () => MockClient((request) async =>
              request.url.path.contains('billing')
                  ? http.Response('{}', 404)
                  : http.Response('[]', 200,
                      headers: {'content-type': 'application/json'})));
    });
  }
}
