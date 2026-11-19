import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_edge_shell.dart';
import 'package:hexora/presentation/shared/widgets/user_profile_popup.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _UserDomain extends ChangeNotifier implements UserDomain {
  _UserDomain(this._user);

  final User _user;

  @override
  User? get user => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('expanded sidebar profile menu opens without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final user = User(
      id: 'user-1',
      name: 'Michel',
      displayName: 'Michel',
      email: 'michel@example.com',
      userName: 'michel',
      groupIds: const ['group-1'],
      emailVerified: true,
    );
    final userDomain = _UserDomain(user);
    addTearDown(userDomain.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<UserDomain>.value(
        value: userDomain,
        child: MaterialApp(
          theme: AppTheme.fromBrightness(Brightness.light),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 248,
                height: 620,
                child: SidebarFooterScope(
                  builder: (_, collapsed) => UserProfilePopup(
                    user: user,
                    placement: UserProfilePopupPlacement.sidebar,
                    expanded: !collapsed,
                    roleLabel: 'Administrador',
                  ),
                  child: SidebarEdgeShell(
                    collapsed: false,
                    onToggle: () {},
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Michel'));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias'), findsOneWidget);
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
