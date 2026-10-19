import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_runtime.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_sheet.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('navy is limited to the wide web conversation panel',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: InsightsChatSheet(
        groupId: 'theme-test',
        embedded: true,
        runtime: InsightsChatRuntime.instanceFor('theme-test'),
      )),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final input = tester.element(find.byType(TextField).first);
    expect(Theme.of(input).brightness,
        kIsWeb ? Brightness.dark : Brightness.light);
    if (kIsWeb) {
      expect(Theme.of(input).colorScheme.surface, AppColors.dashboardTopBar);
    }
    final response = tester.element(find.text('Selecciona una respuesta'));
    expect(Theme.of(response).brightness, Brightness.light);
    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(TextField).first)).brightness,
        Brightness.light);
    expect(tester.takeException(), isNull);
  });
}
