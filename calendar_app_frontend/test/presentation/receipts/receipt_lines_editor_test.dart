import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/widgets/receipt_line_draft.dart';
import 'package:hexora/presentation/screens/workspace/sections/receipts/editor/widgets/receipt_lines_editor.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Widget appFor(List<ReceiptLineDraft> lines) => MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReceiptLinesEditor(
            lines: lines,
            canEdit: true,
            onRemove: (_) {},
            onChanged: () {},
          ),
        ),
      );

  testWidgets('uses compact table rows without a repeated total on desktop',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final line = ReceiptLineDraft.empty();
    addTearDown(line.dispose);
    line.descriptionCtrl.text = 'Servicio';
    line.unitCtrl.text = '23';

    await tester.pumpWidget(appFor([line]));
    await tester.pumpAndSettle();

    expect(find.text('Acc.'), findsOneWidget);
    expect(find.text('Total líneas'), findsNothing);
    expect(find.textContaining('23,00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adapts receipt lines without horizontal scrolling on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final line = ReceiptLineDraft.empty();
    addTearDown(line.dispose);

    await tester.pumpWidget(appFor([line]));
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
