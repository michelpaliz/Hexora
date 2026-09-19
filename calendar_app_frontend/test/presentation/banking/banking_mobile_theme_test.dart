import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/mobile/statements_mobile_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/all_data/mobile/statements_mobile_view.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/statements_controller.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'banking $brightness at 320px and ${scale}x text remains usable',
          (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = StatementsController();
        addTearDown(controller.dispose);
        controller.allEntries = [
          {
            '_id': 'one',
            'description': 'Mantenimiento de jardines y servicios',
            'date': DateTime.now().toIso8601String(),
            'amount': '-443.88'
          },
          {
            '_id': 'two',
            'description': 'Factura cliente',
            'date': DateTime.now().toIso8601String(),
            'amount': '151.25'
          },
        ];
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            theme: AppTheme.forPlatform(brightness,
                platform: TargetPlatform.android),
            locale: const Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: StatementsMobileView()),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (scale == 1.0) {
          final card = find.byType(StatementsMobileCard).first;
          expect(tester.getSize(card).height, lessThan(90));
          final note =
              find.descendant(of: card, matching: find.byType(IconButton));
          final titleRect = tester
              .getRect(find.text('Mantenimiento de jardines y servicios'));
          final amount = find
              .descendant(of: card, matching: find.byType(Text))
              .evaluate()
              .where(
                  (element) => (element.widget as Text).data!.contains('443'))
              .single;
          final amountRect = tester.getRect(find.byWidget(amount.widget));
          expect(tester.getSize(note).height, greaterThanOrEqualTo(48));
          expect(
              (amountRect.center.dy - titleRect.center.dy).abs(), lessThan(2));
        }
        expect(find.byType(ChoiceChip), findsNothing);
        expect(find.text('Este mes · Todos'), findsOneWidget);
        await tester.tap(find.text('Cambiar filtros'));
        await tester.pumpAndSettle();
        final income = find.widgetWithText(ListTile, 'Ingresos');
        await tester.scrollUntilVisible(income, 160,
            scrollable: find.byType(Scrollable).last);
        await tester.pumpAndSettle();
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: income, matching: find.byType(RichText)).first,
        );
        final cs = Theme.of(tester.element(income)).colorScheme;
        final foreground = paragraph.text.style!.color!;
        final a = foreground.computeLuminance();
        final b = cs.surface.computeLuminance();
        final ratio = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
        expect(ratio, greaterThanOrEqualTo(4.5));
        await tester.tap(income);
        await tester.pumpAndSettle();
        // Dismissal must discard the draft selection.
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.text('Este mes · Todos'), findsOneWidget);
        await tester.tap(find.text('Cambiar filtros'));
        await tester.pumpAndSettle();
        final expense = find.widgetWithText(ListTile, 'Gastos');
        await tester.scrollUntilVisible(expense, 160,
            scrollable: find.byType(Scrollable).last);
        await tester.pumpAndSettle();
        await tester.tap(expense);
        await tester.tap(find.text('Aplicar filtros'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Este mes · Gastos'), findsOneWidget);
        expect(find.text('Factura cliente'), findsNothing);
        expect(
            find.text('Mantenimiento de jardines y servicios'), findsOneWidget);
        await tester.tap(find.text('Cambiar filtros'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Restablecer filtros'));
        await tester.tap(find.text('Aplicar filtros'));
        await tester.pumpAndSettle();
        expect(find.text('Todos · Todos'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Factura cliente'), 160,
            scrollable: find.byType(Scrollable).last);
        expect(find.text('Factura cliente'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
