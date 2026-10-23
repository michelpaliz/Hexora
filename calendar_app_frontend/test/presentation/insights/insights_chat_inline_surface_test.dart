import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_message.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_runtime.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_sheet.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/sheet/insights_chat_sheet_base.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('desktop banking results use the full response workspace',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1775, 887);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final rows = List.generate(
      10,
      (index) => <String, dynamic>{
        'id': 'entry-$index',
        'row': index + 1,
        'date': '2026-10-${20 - index}',
        'concept': 'Movimiento bancario de prueba $index',
        'amount': 38.30 + index,
        'amountFormatted': '${(38.30 + index).toStringAsFixed(2)} EUR',
      },
    );
    final message = ChatMessage(
      isUser: false,
      text: 'Ingresos bancarios sin factura vinculada',
      timestamp: DateTime(2026, 10, 20, 20, 49),
      view: 'table',
      table: <String, dynamic>{
        'columns': const [
          {'key': 'row', 'label': '#'},
          {'key': 'date', 'label': 'Fecha'},
          {'key': 'concept', 'label': 'Concepto'},
          {'key': 'amountFormatted', 'label': 'Importe', 'align': 'right'},
        ],
        'rows': rows,
        'summary': const {
          'label': 'Total periodo',
          'amountFormatted': '95.856,87 EUR',
        },
      },
    );
    SharedPreferences.setMockInitialValues({
      'insights_chat_history::anon::layout-regression': jsonEncode({
        'messages': [message.toJson()],
      }),
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InsightsChatSheet(
          groupId: 'layout-regression',
          embedded: true,
          runtime: InsightsChatRuntime.instanceFor('layout-regression'),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final chatWidth = tester
        .getSize(find.byKey(const ValueKey('insights-desktop-chat-pane')))
        .width;
    final tableWidth = tester
        .getSize(find.byKey(const ValueKey('insights-results-table')))
        .width;
    expect(chatWidth, inInclusiveRange(500, 520));
    expect(tableWidth, greaterThan(1100));
    expect(find.text('Vincular'), findsWidgets);
    expect(find.text('126 movimientos'), findsNothing);
    expect(find.text('10 movimientos'), findsOneWidget);
    expect(find.text('95.856,87 €'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline surface docks beside the chat without a new route',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final key = GlobalKey<InsightsChatSheetStateBase>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(
        Brightness.light,
        platform: TargetPlatform.windows,
      ),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: InsightsChatSheet(
          key: key,
          groupId: 'inline-surface-test',
          embedded: true,
          runtime: InsightsChatRuntime.instanceFor('inline-surface-test'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final state = key.currentState!;
    state.showInlineSurface(const Text('INLINE_SURFACE_WIDE'));
    await tester.pumpAndSettle();
    expect(find.text('INLINE_SURFACE_WIDE'), findsOneWidget);
    expect(find.text('Selecciona una respuesta'), findsOneWidget);
    expect(tester.takeException(), isNull);

    state.closeInlineSurface();
    await tester.pumpAndSettle();
    expect(find.text('INLINE_SURFACE_WIDE'), findsNothing);
    expect(find.text('Selecciona una respuesta'), findsOneWidget);

    tester.view.physicalSize = const Size(600, 900);
    await tester.pumpAndSettle();
    state.showInlineSurface(const Text('INLINE_SURFACE_NARROW'));
    await tester.pumpAndSettle();
    expect(find.text('INLINE_SURFACE_NARROW'), findsOneWidget);
    expect(tester.takeException(), isNull);

    state.closeInlineSurface();
    await tester.pumpAndSettle();
    expect(find.text('INLINE_SURFACE_NARROW'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
