import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/statements_ai_match_suggest_dialog.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Future<void> pumpFooter(
    WidgetTester tester, {
    Size size = const Size(880, 700),
    double textScale = 1.0,
    bool narrow = false,
    bool confirming = false,
    bool applying = false,
    bool canApply = true,
    bool hasSelection = true,
    int? total,
    bool showClose = true,
    List<String> warnings = const <String>[],
    VoidCallback? onApply,
    VoidCallback? onConfirm,
    VoidCallback? onCancelConfirm,
    VoidCallback? onManual,
    VoidCallback? onClose,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.dark,
          platform: TargetPlatform.android,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Builder(
                  builder: (context) =>
                      StatementsAiMatchSuggestDialog.buildFooterForTest(
                    context,
                    narrow: narrow,
                    confirming: confirming,
                    applying: applying,
                    canApply: canApply,
                    hasSelection: hasSelection,
                    total: total,
                    showClose: showClose,
                    confirmWarnings: warnings,
                    onApply: onApply,
                    onConfirm: onConfirm,
                    onCancelConfirm: onCancelConfirm,
                    onManual: onManual,
                    onClose: onClose,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applying) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  FilledButton filledButtonWith(WidgetTester tester, String label) {
    return tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((widget) => widget is FilledButton),
      ),
    );
  }

  testWidgets('footer exposes link and manual actions without a dialog',
      (tester) async {
    var apply = 0;
    var manual = 0;
    var close = 0;
    await pumpFooter(
      tester,
      onApply: () => apply++,
      onManual: () => manual++,
      onClose: () => close++,
    );

    expect(find.text('Vincular coincidencia'), findsOneWidget);
    expect(find.text('Vincular manualmente'), findsOneWidget);
    expect(find.text('Confirmar y vincular'), findsNothing);

    await tester.tap(find.text('Vincular coincidencia'));
    await tester.tap(find.text('Vincular manualmente'));
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(apply, 1);
    expect(manual, 1);
    expect(close, 1);
  });

  testWidgets('confirmation is inline in the footer and keeps warnings visible',
      (tester) async {
    var confirmed = 0;
    var cancelled = 0;
    await pumpFooter(
      tester,
      confirming: true,
      warnings: const <String>[
        'el importe no coincide',
        'la confianza es baja',
      ],
      onConfirm: () => confirmed++,
      onCancelConfirm: () => cancelled++,
    );

    expect(
      find.text(
        'Revisa antes de vincular: el importe no coincide · la confianza es baja.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Confirmar y vincular'), findsOneWidget);
    expect(find.text('Vincular manualmente'), findsNothing);
    expect(find.text('Vincular coincidencia'), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      tester.getCenter(find.text('Confirmar y vincular')).dx,
      greaterThan(880 / 2),
    );

    await tester.tap(find.text('Confirmar y vincular'));
    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(confirmed, 1);
    expect(cancelled, 1);
  });

  testWidgets('inline confirmation fits 320px at 2x text', (tester) async {
    await pumpFooter(
      tester,
      size: const Size(320, 900),
      textScale: 2.0,
      narrow: true,
      confirming: true,
      warnings: const <String>['el importe no coincide'],
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Confirmar y vincular'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('applying disables the inline confirmation button',
      (tester) async {
    await pumpFooter(tester, confirming: true, applying: true);

    final button = filledButtonWith(tester, 'Vinculando...');
    expect(button.onPressed, isNull);
  });

  testWidgets('footer disables linking when no suggestion is selected',
      (tester) async {
    await pumpFooter(tester, hasSelection: false, total: 2, canApply: false);

    final button = filledButtonWith(tester, 'Vincular coincidencia');
    expect(button.onPressed, isNull);
    expect(find.text('Vincular manualmente'), findsOneWidget);
  });

  testWidgets('without suggestions manual linking is the primary action',
      (tester) async {
    var manual = 0;
    await pumpFooter(
      tester,
      hasSelection: false,
      canApply: false,
      showClose: false,
      onManual: () => manual++,
    );

    expect(find.text('Vincular coincidencia'), findsNothing);
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Sin alternativas disponibles.'), findsOneWidget);
    final button = filledButtonWith(tester, 'Vincular manualmente');
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Vincular manualmente'));
    expect(manual, 1);
  });

  testWidgets('narrow footer without suggestions fits 320px at 2x text',
      (tester) async {
    await pumpFooter(
      tester,
      size: const Size(320, 900),
      textScale: 2.0,
      narrow: true,
      hasSelection: false,
      canApply: false,
      showClose: false,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Vincular manualmente'), findsOneWidget);
  });
}
