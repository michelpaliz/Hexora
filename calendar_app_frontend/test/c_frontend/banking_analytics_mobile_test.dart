import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/analytics/mobile/statements_analytics_mobile.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/analytics/statements_analytics_controller.dart';
import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _Controller extends StatementsAnalyticsController {
  int loads = 0;
  @override
  Future<void> loadBatches() async {
    loads++;
    batchesError = null;
    batches = [
      {'id': 'one', 'originalName': 'Banco'}
    ];
    selectedBatchId = 'all';
    summary = {
      'years': [
        {'year': 2026, 'income': 1000, 'expense': 200, 'net': 800, 'count': 2}
      ]
    };
    notifyListeners();
  }
}

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
        'analytics filters and retry work with route-scoped provider at $scale',
        (tester) async {
      tester.view.physicalSize = const Size(390, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _Controller();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<StatementsAnalyticsController>.value(
          value: controller,
          child: const Scaffold(body: StatementsMobileAnalyticsView()),
        ),
      ));
      await tester.pumpAndSettle();
      expect(controller.loads, 1);
      expect(tester.takeException(), isNull);
      final l = AppLocalizations.of(
          tester.element(find.byType(StatementsMobileAnalyticsView)))!;
      await tester.tap(find.byTooltip(l.statementsFiltersTitle));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomSheet), findsOneWidget);
      controller.top = 20;
      controller.notifyListeners();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      controller.batchesError = 'Connection failed';
      controller.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Connection failed'), findsOneWidget);
      await tester.tap(find.text(l.tryAgain));
      await tester.pumpAndSettle();
      expect(controller.loads, 2);
      expect(find.text('Connection failed'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
