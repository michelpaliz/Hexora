import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_compose_screen.dart';
import 'package:hexora/presentation/shared/widgets/buttons/hexora_button.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('desktop composer restores attachment panel and compact send bar',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MailComposeScreen(),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Adjuntar facturas'), findsOneWidget);
    final send = find
        .ancestor(
            of: find.text('Enviar correo'), matching: find.byType(HexoraButton))
        .first;
    expect(tester.widget<HexoraButton>(send).onPressed, isNull);
    expect(tester.getSize(send).width, lessThan(300));
    final desktopFrame = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('mail-compose-desktop-frame')),
    );
    expect(
      desktopFrame.color,
      Theme.of(tester.element(find.byKey(
        const ValueKey('mail-compose-desktop-frame'),
      ))).colorScheme.surfaceContainerLowest,
    );
    final editorSurface = tester.widget<Container>(
      find.byKey(const ValueKey('mail-compose-editor-surface')),
    );
    expect(
      (editorSurface.decoration! as BoxDecoration).color,
      Theme.of(tester.element(find.byKey(
        const ValueKey('mail-compose-editor-surface'),
      ))).colorScheme.surface,
    );
    final context = tester.element(
      find.byKey(const ValueKey('mail-compose-subject-input-surface')),
    );
    final expectedFill = Theme.of(context).inputDecorationTheme.fillColor ??
        Theme.of(context).colorScheme.surfaceContainerLow;
    for (final key in const [
      'mail-compose-recipient-input-surface',
      'mail-compose-subject-input-surface',
    ]) {
      final container = tester.widget<Container>(find.byKey(ValueKey(key)));
      expect((container.decoration! as BoxDecoration).color, expectedFill);
    }
    final bodySurface = tester.widget<Container>(
      find.byKey(const ValueKey('mail-compose-body-input-surface')),
    );
    expect(
      (bodySurface.decoration! as BoxDecoration).color,
      Theme.of(context).colorScheme.surface,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('mail-compose-editor-surface')))
          .width,
      lessThan(1000),
    );
    expect(
      find.byKey(const ValueKey('mail-compose-options-surface')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('mail-compose-add-attachment')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Adjuntar documentos'), findsOneWidget);
  });

  testWidgets('composer inherits the dark theme input surface', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.dark,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MailComposeScreen(),
    ));
    await tester.pumpAndSettle();

    final finder =
        find.byKey(const ValueKey('mail-compose-body-input-surface'));
    final context = tester.element(finder);
    final container = tester.widget<Container>(finder);
    expect(
      (container.decoration! as BoxDecoration).color,
      Theme.of(context).inputDecorationTheme.fillColor,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('composer surface reacts to runtime theme changes',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themeMode = ValueNotifier(ThemeMode.light);
    addTearDown(themeMode.dispose);
    await tester.pumpWidget(ValueListenableBuilder<ThemeMode>(
      valueListenable: themeMode,
      child: const MailComposeScreen(),
      builder: (context, mode, child) => MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        darkTheme: AppTheme.forPlatform(
          Brightness.dark,
          platform: TargetPlatform.windows,
        ),
        themeMode: mode,
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          quill.FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ));
    await tester.pumpAndSettle();

    const workspaceKey = ValueKey('mail-compose-editor-surface');
    Color workspaceColor() {
      final finder = find.byKey(workspaceKey);
      return (tester.widget<Container>(finder).decoration! as BoxDecoration)
          .color!;
    }

    final lightColor = workspaceColor();
    expect(
      Theme.of(tester.element(find.byKey(workspaceKey))).brightness,
      Brightness.light,
    );

    themeMode.value = ThemeMode.dark;
    await tester.pumpAndSettle();

    final darkContext = tester.element(find.byKey(workspaceKey));
    expect(Theme.of(darkContext).brightness, Brightness.dark);
    expect(workspaceColor(), Theme.of(darkContext).colorScheme.surface);
    expect(workspaceColor(), isNot(lightColor));
    expect(tester.takeException(), isNull);
  });
  for (final scale in [1.0, 1.5]) {
    testWidgets('mobile composer supports recipients and keyboard at $scale',
        (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.android),
        locale: const Locale('es'),
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          quill.FlutterQuillLocalizations.delegate
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!),
        home: const MailComposeScreen(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Redactar'), findsOneWidget);
      final email = find
          .byWidgetPredicate((w) =>
              w is TextField && w.keyboardType == TextInputType.emailAddress)
          .first;
      expect(tester.getSize(email).width, greaterThan(240));
      await tester.enterText(email, 'person@example.com ');
      await tester.pumpAndSettle();
      expect(find.text('person@example.com'), findsOneWidget);
      await tester.tap(find.text('Añadir Cc'));
      await tester.pumpAndSettle();
      expect(
          find.byWidgetPredicate((w) =>
              w is TextField && w.keyboardType == TextInputType.emailAddress),
          findsNWidgets(2));
      expect(tester.takeException(), isNull);
      final subject = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'Asunto');
      await tester.ensureVisible(subject);
      await tester.enterText(subject, 'Visita de mañana');
      final editor =
          tester.widget<quill.QuillEditor>(find.byType(quill.QuillEditor));
      editor.controller.document.insert(0, 'Hola, confirmamos la visita.');
      await tester.pumpAndSettle();
      final send = find
          .ancestor(
              of: find.text('Enviar correo'),
              matching: find.byType(HexoraButton))
          .first;
      expect(tester.widget<HexoraButton>(send).onPressed, isNotNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(find.text('Enviar correo').hitTestable(), findsOneWidget);
      expect(
          tester.getBottomRight(find.text('Enviar correo')).dy, lessThan(480));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
