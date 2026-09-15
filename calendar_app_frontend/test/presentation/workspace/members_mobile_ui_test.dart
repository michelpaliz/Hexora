import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/role_dialog/role_edit_dialog.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/member_row/member_detail_sheet.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/widgets/add_users_flow/widgets/member_role_tile.dart';
import 'package:hexora/presentation/screens/workspace/sections/members/presentation/screen/tabs/update_role_tab.dart';
import 'package:hexora/presentation/utils/roles/group_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
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

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
      locale: const Locale('es'),
      theme: ThemeData(
        brightness: dark ? Brightness.dark : Brightness.light,
        extensions: const [_typography],
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

User user({String email = ''}) => User(
    id: 'u1',
    name: 'Alejandro Fernández de la Comunidad',
    userName: 'alejandro',
    email: email,
    groupIds: [],
    emailVerified: true);

void main() {
  for (final dark in [false, true]) {
    testWidgets('member details readable and actions reachable dark=$dark',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      var removed = 0;
      var closed = 0;
      await tester.pumpWidget(_app(
          MemberDetailContent(
              user: user(),
              role: GroupRole.coAdmin,
              onClose: () => closed++,
              onRemove: () async => removed++),
          dark: dark));
      await tester.pumpAndSettle();
      expect(find.text('Co-Administrador'), findsOneWidget);
      expect(find.text('@alejandro'), findsOneWidget);
      expect(find.byIcon(Icons.alternate_email), findsNothing);
      final name = tester.widget<Text>(find.text(user().name));
      final cs = Theme.of(tester.element(find.byType(MemberDetailContent)))
          .colorScheme;
      expect(name.style?.color, cs.onSurface);
      final luminances = [
        cs.onSurface.computeLuminance(),
        cs.surface.computeLuminance()
      ]..sort();
      expect(
          (luminances.last + .05) / (luminances.first + .05), greaterThan(4.5));
      await tester.ensureVisible(find.text('Eliminar'));
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();
      expect(removed, 1);
      await tester.ensureVisible(find.byIcon(Icons.close));
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('role dialog text uses surface colors dark=$dark',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(
          RoleEditDialog(
            user: user(),
            userId: 'u1',
            current: GroupRole.coAdmin,
            options: const [GroupRole.member, GroupRole.coAdmin],
          ),
          dark: dark));
      await tester.pumpAndSettle();
      final cs =
          Theme.of(tester.element(find.byType(RoleEditDialog))).colorScheme;
      expect(tester.widget<Text>(find.text(user().name)).style?.color,
          cs.onSurface);
      expect(find.text('Guardar cambios').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'role list scrolls with long names and localized picker dark=$dark',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 740);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      GroupRole? changed;
      await tester.pumpWidget(_app(
          UpdateRolesTab(
            rolesByUserId: {
              for (var i = 0; i < 10; i++) 'u$i': GroupRole.coAdmin
            },
            membersById: {for (var i = 0; i < 10; i++) 'u$i': user()},
            assignableRoles: const [GroupRole.member, GroupRole.coAdmin],
            canEditRole: (_) => true,
            setRole: (_, role) => changed = role,
            actorIsOwner: true,
          ),
          dark: dark));
      await tester.pumpAndSettle();
      final name = tester.widget<Text>(find.text(user().name).first);
      expect(name.maxLines, isNull);
      await tester.ensureVisible(find.byType(MemberRoleTile).first);
      await tester.tap(find.text(user().name).first);
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(BottomSheet)))!;
      expect(find.text(l.changeRole), findsOneWidget);
      final memberOption = find.descendant(
          of: find.byType(BottomSheet), matching: find.text(l.member));
      await tester.ensureVisible(memberOption);
      await tester.tap(memberOption);
      await tester.pumpAndSettle();
      expect(changed, GroupRole.member);
      await tester.ensureVisible(find.byType(MemberRoleTile).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
