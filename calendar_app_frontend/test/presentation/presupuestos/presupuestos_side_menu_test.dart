import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/presupuestos_module_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets(
      'proposals sidebar groups module destinations without duplicate headings',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SizedBox(
          width: 248,
          child: PresupuestosSideMenu(
            selected: 'budgets_document_all',
            onSelected: (_) {},
            collapsed: false,
            onToggleCollapse: () {},
          ),
        ),
      ),
    ));

    expect(find.text('Propuestas'), findsOneWidget);
    expect(find.text('Todas las propuestas'), findsOneWidget);
    expect(find.text('RECURSOS'), findsOneWidget);
    expect(find.text('Plantillas'), findsOneWidget);
    expect(find.text('Biblioteca de imágenes'), findsOneWidget);
    // Status filtering and the primary action now live in the main page.
    expect(find.text('Nueva propuesta'), findsNothing);
    expect(find.text('DOCUMENTOS'), findsNothing);
    expect(find.text('Todos'), findsNothing);
    expect(find.text('Borradores'), findsNothing);
    expect(find.text('Emitidas'), findsNothing);

    double top(String label) => tester.getTopLeft(find.text(label)).dy;

    expect(top('Todas las propuestas'), greaterThan(top('Propuestas')));
    expect(top('Plantillas'), greaterThan(top('RECURSOS')));
    expect(top('Biblioteca de imágenes'), greaterThan(top('Plantillas')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('proposals sidebar navigates to module destinations',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? selected;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SizedBox(
          width: 248,
          child: PresupuestosSideMenu(
            selected: 'budgets_document_all',
            onSelected: (value) => selected = value,
            collapsed: false,
            onToggleCollapse: () {},
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Todas las propuestas'));
    await tester.pump();
    expect(selected, 'budgets_document_all');

    await tester.tap(find.text('Plantillas'));
    await tester.pump();
    expect(selected, 'budget_templates');

    await tester.tap(find.text('Biblioteca de imágenes'));
    await tester.pump();
    expect(selected, 'budget_image_library');
  });
}
