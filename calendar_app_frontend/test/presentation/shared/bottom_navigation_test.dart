import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user_model/user.dart';
import 'package:hexora/services/user/domain/user_domain.dart';
import 'package:hexora/presentation/routes/appRoutes.dart';
import 'package:hexora/navigation/main_scaffold.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class _UserDomain extends ChangeNotifier implements UserDomain {
  @override
  User? get user => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
        'navigation fits a small phone and follows routes in $brightness',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ChangeNotifierProvider<UserDomain>(
        create: (_) => _UserDomain(),
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 24),
              viewPadding: const EdgeInsets.only(bottom: 24),
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          ),
          initialRoute: AppRoutes.homePage,
          routes: {
            AppRoutes.homePage: (_) =>
                const MainScaffold(body: Text('Home body')),
            AppRoutes.profileDetails: (_) =>
                const MainScaffold(body: Text('Profile body')),
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      final nav = tester.getRect(find.byType(NavigationBar));
      final fab = tester.getRect(find.byType(FloatingActionButton));
      expect(fab.bottom, lessThanOrEqualTo(nav.top));
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      expect(find.text('Profile body'), findsOneWidget);
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2);
      // Missing authentication must not select a destination that did not open.
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          2);
      expect(tester.takeException(), isNull);
    });
  }
}
