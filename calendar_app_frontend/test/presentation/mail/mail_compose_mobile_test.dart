import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:hexora/presentation/screens/workspace/sections/mail/mail_compose_screen.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
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
