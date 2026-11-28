import 'package:flutter/material.dart';
import 'package:hexora/theme/typography/typography_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/user/user.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/home/home_page/widgets/home_overview.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/repositories/auth_repository.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/state/user_preferences_provider.dart';

class _Groups extends ChangeNotifier implements GroupDomain {
  @override
  bool get groupsLoading => false;
  @override
  Object? get groupsLoadError => null;
  @override
  Stream<List<Group>> watchGroupsForUser(String id) => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users extends ChangeNotifier implements UserDomain {
  _Users(User user) : currentUserNotifier = ValueNotifier(user);
  @override
  final ValueNotifier<User?> currentUserNotifier;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void dispose() {
    currentUserNotifier.dispose();
    super.dispose();
  }
}

class _NoRequests extends Fake implements AuthRepository {}

void main() {
  for (final width in [360.0, 1024.0, 1440.0]) {
    testWidgets('home overview fits $width and opens its quick guide',
        (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final user = User(
          id: 'u',
          name: 'Michael',
          email: 'test@example.com',
          userName: 'michael',
          groupIds: [],
          emailVerified: true);
      await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<UserDomain>(create: (_) => _Users(user)),
            ChangeNotifierProvider<GroupDomain>(create: (_) => _Groups()),
            ChangeNotifierProvider(create: (_) => AuthService(_NoRequests())),
            ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [AppTypography.light()]),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: HomeOverview(
              user: user,
              groupsKey: GlobalKey(),
              onSettings: () {},
              onProfile: () {},
            ))),
          )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('1 de 3 datos completados'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver guía rápida'));
      await tester.tap(find.text('Ver guía rápida'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Tu espacio en Hexora'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Entendido'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('Ver todo'));
      await tester.tap(find.text('Ver todo'));
      await tester.pump();
      expect(find.byKey(const ValueKey('announcements-dialog-header')),
          findsOneWidget);
      expect(find.byType(Dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
