import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_compose_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/theme/colors/app_colors.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('desktop composer shows invoice panel and compact send bar',
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
    expect(
      find.text('Selecciona el cliente y las facturas que quieres enviar.'),
      findsNothing,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('mail-attachment-compact-header')),
          )
          .height,
      40,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('mail-attachment-inline-stepper')),
          )
          .height,
      32,
    );
    expect(find.text('Continuar'), findsOneWidget);
    final send = find
        .ancestor(
            of: find.text('Enviar correo'),
            matching: find.byWidgetPredicate((w) => w is FilledButton))
        .first;
    expect(tester.widget<FilledButton>(send).onPressed, isNull);
    expect(tester.getSize(send).width, lessThan(300));
    expect(tester.getTopLeft(find.text('Adjuntar facturas')).dx,
        lessThan(tester.getTopLeft(find.byType(quill.QuillEditor)).dx));
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('mail-compose-editor-header')),
          )
          .dx,
      lessThan(
        tester.getTopLeft(find.text('Adjuntar facturas')).dx,
      ),
    );
    final optionsSurface = find.byKey(
      const ValueKey('mail-compose-options-surface'),
    );
    final optionsBackground = tester.widget<ColoredBox>(
      find
          .descendant(
            of: optionsSurface,
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(optionsBackground.color, AppDarkColors.sidebar);
    final desktopFrame = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('mail-compose-desktop-frame')),
    );
    expect(desktopFrame.color, AppDarkColors.sidebar);
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
    final expectedFill = Theme.of(context).inputDecorationTheme.fillColor;
    for (final key in const [
      'mail-compose-recipient-input-surface',
      'mail-compose-subject-input-surface',
      'mail-compose-body-input-surface',
    ]) {
      final container = tester.widget<Container>(find.byKey(ValueKey(key)));
      expect((container.decoration! as BoxDecoration).color, expectedFill);
    }
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
              matching: find.byWidgetPredicate((w) => w is FilledButton))
          .first;
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
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
