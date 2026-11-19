import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/enable_banking_left_nav.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_controller.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/analytics/statements_analytics_view.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

class _AnalyticsController extends StatementsAnalyticsController {
  @override
  Future<void> loadBatches() async {
    batches = [
      {'id': 'batch-1', 'originalName': 'Banco'}
    ];
    selectedBatchId = 'all';
    entries = List.generate(14, (index) {
      final date = DateTime(2026, 11, index + 1);
      return {
        'date': date.toIso8601String(),
        'amount': index.isEven ? 100 : -50,
      };
    });
    notifyListeners();
  }
}

void main() {
  testWidgets('analytics uses a compact filter popover and heatmap',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = _AnalyticsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<StatementsAnalyticsController>.value(
          value: controller,
          child: const Scaffold(
            body: StatementsAnalyticsView(
              section: EnableBankingMenu.analyticsActivity,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final localizations = AppLocalizations.of(
      tester.element(find.byType(StatementsAnalyticsView)),
    )!;
    expect(find.text('Actividad diaria'), findsOneWidget);
    expect(find.text(localizations.statementsFiltersActive), findsNothing);
    expect(
        tester.getSize(find.byType(GridView)).height, lessThanOrEqualTo(120));

    await tester.tap(find.byTooltip(localizations.statementsFiltersTitle));
    await tester.pumpAndSettle();

    expect(find.text(localizations.statementsAnalyticsBatch), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
