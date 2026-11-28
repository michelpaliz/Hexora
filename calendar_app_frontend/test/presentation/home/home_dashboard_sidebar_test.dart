import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/home/dashboard_preview/dashboard_preview_screen.dart';
import 'package:hexora/presentation/shared/widgets/sidebar_item.dart';
import 'package:hexora/services/auth/auth_service.dart';
import 'package:hexora/services/auth/repositories/auth_repository.dart';
import 'package:hexora/services/groups/domain/group_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _NoRequests extends Fake implements AuthRepository {}

class _Groups extends ChangeNotifier implements GroupDomain {
  @override
  Group? get currentGroup => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('embedded Home provides collapsible in-page dashboard navigation',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GroupDomain>(create: (_) => _Groups()),
          ChangeNotifierProvider(create: (_) => AuthService(_NoRequests())),
        ],
        child: MaterialApp(
          theme: AppTheme.fromBrightness(Brightness.light),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DashboardPreviewScreen(
              embedded: true,
              onAskHexora: (_, __) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    for (final key in [
      'summary',
      'business',
      'assistant',
      'financial',
      'activity',
      'tasks',
      'documents',
      'news',
      'help',
    ]) {
      expect(find.byKey(ValueKey('home-dashboard-nav-$key')), findsOneWidget);
    }
    expect(find.text('INICIO'), findsOneWidget);
    expect(find.text('ACTIVIDAD'), findsOneWidget);
    expect(find.text('HEXORA'), findsOneWidget);

    final summary = find.byKey(const ValueKey('home-dashboard-nav-summary'));
    expect(tester.widget<SidebarItem>(summary).isSelected, isTrue);

    await tester
        .tap(find.byKey(const ValueKey('home-dashboard-nav-documents')));
    await tester.pump(const Duration(milliseconds: 420));
    expect(
      tester
          .widget<SidebarItem>(
              find.byKey(const ValueKey('home-dashboard-nav-documents')))
          .isSelected,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('collapsible-sidebar-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Resumen'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
