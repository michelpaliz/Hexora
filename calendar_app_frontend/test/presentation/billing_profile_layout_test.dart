import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/invoice/billing_profile.dart';
import 'package:hexora/services/invoicing/billing_profile_api.dart';
import 'package:hexora/presentation/screens/workspace/sections/invoices/group_invoices/widgets/billing_profile_inline_editor.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  for (final width in [390.0, 1400.0]) {
    testWidgets('billing footer stays outside scroll area at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPlatform(Brightness.light,
            platform: TargetPlatform.windows),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
            body: BillingProfileInlineEditor(
          initial: const BillingProfile(
              groupId: 'group', legalName: 'Empresa', taxId: 'B12345678'),
          groupId: 'group',
          api: BillingProfileApi(),
          onSaved: (_) {},
          showFolder: false,
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final save = find.byKey(const ValueKey('billing-profile-save'));
      expect(save, findsOneWidget);
      expect(tester.getBottomLeft(find.byType(SingleChildScrollView)).dy,
          lessThanOrEqualTo(tester.getTopLeft(save).dy));
      final firstField = find.byType(TextFormField).first;
      await tester.ensureVisible(firstField);
      await tester.enterText(firstField, 'Empresa nueva');
      await tester.pump();
      expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
      await tester.tap(find.text('Descartar cambios'));
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });
  }
}
