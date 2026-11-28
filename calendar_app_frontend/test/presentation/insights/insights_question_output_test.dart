import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_money_format.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_question_suggestions.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_sheet.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_runtime.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat/insights_chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  testWidgets('structured answers render localized table amounts and totals',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const group = 'localized-ask-output';
    final message = ChatMessage(
        isUser: false,
        text: 'Resultados',
        timestamp: DateTime(2026, 11, 28),
        view: 'table',
        table: {
          'columns': [
            {'key': 'concept', 'label': 'Concepto'},
            {'key': 'amountFormatted', 'label': 'Importe', 'align': 'right'},
          ],
          'rows': [
            {
              'concept': 'Servicio',
              'amount': 1234.56,
              'amountFormatted': '1,234.56 EUR'
            }
          ],
          'summary': {'label': 'Total', 'amountFormatted': '1,234.56 EUR'},
        });
    SharedPreferences.setMockInitialValues({
      'insights_chat_history::anon::$group': jsonEncode({
        'messages': [message.toJson()]
      }),
    });
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.forPlatform(Brightness.light,
          platform: TargetPlatform.windows),
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: InsightsChatSheet(
              groupId: group,
              embedded: true,
              runtime: InsightsChatRuntime.instanceFor(group))),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    expect(
        find.byWidgetPredicate((widget) =>
            widget is Text &&
            widget.data?.replaceAll('\u00a0', ' ') == '1.234,56 €'),
        findsWidgets);
    expect(find.text('1,234.56 EUR'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['es', 'en']) {
    testWidgets('suggestions and monetary results follow $language',
        (tester) async {
      late BuildContext context;
      String? question;
      await tester.pumpWidget(MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Builder(builder: (ctx) {
          context = ctx;
          return InsightsQuestionSuggestions(
              onSelected: (value) => question = value);
        })),
      ));
      await tester.tap(find
          .text(language == 'es' ? 'Facturas pendientes' : 'Unpaid invoices'));
      expect(question, contains(language == 'es' ? 'una tabla' : 'a table'));
      final expected = language == 'es' ? '1.234,56 €' : '€1,234.56';
      String format(dynamic value, {String? currency}) =>
          formatInsightsMoney(context, value, currency: currency)
              .replaceAll('\u00a0', ' ');
      expect(format(1234.56), expected);
      expect(format('1,234.56 EUR'), expected);
      expect(format('1.234,56 €'), expected);
      expect(format(-1234.56), '-$expected');
      expect(format(0), language == 'es' ? '0,00 €' : '€0.00');
      expect(format(1234.56, currency: 'USD'), contains('USD'));
      expect(format('1,234.56 USD'), contains('USD'));
      expect(format('Not available'), 'Not available');
      expect(format(null), '');
      expect(format('Pending 3 invoices'), 'Pending 3 invoices');
    });
  }

  test('only money columns are formatted as money', () {
    expect(
        insightsMoneyColumn({'key': 'matchedInvoiceAmountFormatted'}), isTrue);
    expect(insightsMoneyColumn({'key': 'value', 'type': 'currency'}), isTrue);
    expect(insightsMoneyColumn({'key': 'invoiceNumber'}), isFalse);
    expect(insightsMoneyColumn({'key': 'totalCount'}), isFalse);
    expect(insightsMoneyColumn({'key': 'taxRate'}), isFalse);
  });
}
