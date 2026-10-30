import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/clients/client.dart';
import 'package:hexora/presentation/screens/workspace/sections/presupuestos/views/presupuestos_view.dart';
import 'package:hexora/services/presupuestos/presupuestos_api.dart';
import 'package:hexora/services/auth/token/i_token_store.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';

class _Tokens implements TokenStore {
  @override
  Future<String?> readAccess() async => 'test';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements PresupuestosApi {
  _Api(num? advance)
      : budget = {
          '_id': 'budget-1',
          'status': 'draft',
          'clientId': 'client-1',
          if (advance != null) 'advancePercent': advance,
          'lines': [
            {
              'description': 'Maintenance',
              'quantity': 1,
              'unitPrice': 300,
              'taxRate': 21
            },
          ],
        };

  final Map<String, dynamic> budget;
  num? savedAdvance;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getById) {
      return Future<Map<String, dynamic>>.value(Map.of(budget));
    }
    if (invocation.memberName == #updateDraft) {
      savedAdvance = invocation.namedArguments[#advancePercent] as num?;
      budget['advancePercent'] = savedAdvance;
      return Future<Map<String, dynamic>>.value(Map.of(budget));
    }
    if (invocation.memberName == #previewPdf) {
      return Future<http.Response>.value(http.Response('', 503));
    }
    return super.noSuchMethod(invocation);
  }
}

Future<void> _pumpEditor(
  WidgetTester tester,
  _Api api, {
  Size size = const Size(1600, 1400),
  bool createNew = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.fromBrightness(Brightness.light),
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: GroupInvoicesBudgetsView(
      api: api,
      groupId: 'group-1',
      clients: [GroupClient(id: 'client-1', groupId: 'group-1', name: 'Arjen')],
      mode: GroupInvoicesBudgetsMode.create,
      initialSelectedBudgetId: createNew ? null : 'budget-1',
    )),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => TokenService.configureStore(_Tokens()));
  tearDown(() => TokenService.configureStore(SecureTokenStore()));
  final advance = find.byKey(const ValueKey('budget_advance_percent'));

  testWidgets('details calculate the advance and preserve notes on return',
      (tester) async {
    await http.runWithClient(() async {
      final api = _Api(30);
      (api.budget['lines'] as List).first['unitPrice'] = 1000;
      (api.budget['lines'] as List).first['taxRate'] = 0;
      api.budget['issueDate'] = '2026-10-18';
      await _pumpEditor(tester, api);
      final amount = find.byKey(const ValueKey('budget_advance_amount'));
      expect(find.descendant(of: amount, matching: find.byType(TextField)),
          findsNothing);
      expect(
          find.descendant(of: amount, matching: find.textContaining('300,00')),
          findsOneWidget);
      expect(find.textContaining('Pendiente: 700,00'), findsOneWidget);
      expect(find.text('Vista previa'), findsOneWidget);
      final notes = find.byKey(const ValueKey('budget_notes'));
      expect(tester.widget<TextField>(notes).minLines, 3);
      await tester.enterText(notes, 'Primera línea\nSegunda línea');
      await tester.tap(find.text('Continuar a líneas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atrás'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(notes).controller!.text,
          'Primera línea\nSegunda línea');
      expect(tester.widget<TextField>(advance).controller!.text, '30');
      await tester.enterText(advance, '10');
      await tester.pump();
      expect(
          find.descendant(of: amount, matching: find.textContaining('100,00')),
          findsOneWidget);
      expect(find.textContaining('Pendiente: 900,00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, () => MockClient((_) async => http.Response('{}', 200)));
  });

  for (final width in [390.0, 900.0, 1600.0]) {
    testWidgets('details layout and fixed navigation at width $width',
        (tester) async {
      await _pumpEditor(tester, _Api(0), size: Size(width, 700));
      final date =
          tester.getRect(find.byKey(const ValueKey('budget_issue_date')));
      final currency =
          tester.getRect(find.byKey(const ValueKey('budget_currency')));
      expect(date.width, closeTo(currency.width, 1));
      if (width < 650) {
        expect(currency.top, greaterThan(date.bottom));
      } else {
        expect(currency.top, closeTo(date.top, 1));
      }
      final header = find.byKey(const ValueKey('budget_wizard_header'));
      final footer = find.byKey(const ValueKey('budget_wizard_actions'));
      final headerRect = tester.getRect(header);
      final footerRect = tester.getRect(footer);
      await tester.drag(find.byKey(const ValueKey('budget_wizard_content')),
          const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.getRect(header), headerRect);
      expect(tester.getRect(footer), footerRect);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 700.0, 1600.0]) {
    testWidgets('final review keeps compact fixed chrome at width $width',
        (tester) async {
      await http.runWithClient(() async {
        await _pumpEditor(
          tester,
          _Api(0),
          size: Size(width, 760),
        );
        tester
            .widget<InkWell>(
              find.byKey(const ValueKey('budget-editor-step-3')),
            )
            .onTap!();
        await tester.pumpAndSettle();

        expect(find.text('Revisión final'), findsOneWidget);
        expect(find.text('Resumen del contenido'), findsOneWidget);
        expect(find.text('Abrir previsualización'), findsNothing);
        expect(
          find.byKey(const ValueKey('budget_wizard_actions')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async => http.Response('{}', 200)));
    });
  }

  testWidgets('new quotations default to today and show an amount placeholder',
      (tester) async {
    await _pumpEditor(tester, _Api(null), createNew: true);
    await tester.tap(find.text('Cliente manual'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find
            .descendant(
                of: find.byKey(const ValueKey('manual')),
                matching: find.byType(TextField))
            .first,
        'Cliente nuevo');
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const ValueKey('budget_issue_date')),
            matching: find.text(DateFormat.yMMMd('es').format(DateTime.now()))),
        findsOneWidget);
    expect(find.text('Se calculará con las líneas'), findsOneWidget);
    expect(find.text('Vista previa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final initial in <num?>[null, 0, 70]) {
    testWidgets('loads advance $initial without inventing a required advance',
        (tester) async {
      await _pumpEditor(tester, _Api(initial));
      final field = tester.widget<TextField>(advance);
      expect(field.controller!.text, '${initial ?? 0}');
      expect(field.decoration!.errorText, isNull);
      expect(tester.takeException(), isNull);
    });
  }

  for (final entry in {'': 0, '0': 0, '25,5': 25.5, '100': 100}.entries) {
    testWidgets('saves optional advance "${entry.key}" as ${entry.value}',
        (tester) async {
      await http.runWithClient(() async {
        final api = _Api(70);
        await _pumpEditor(tester, api);
        await tester.enterText(advance, entry.key);
        await tester.pump();
        expect(tester.widget<TextField>(advance).decoration!.errorText, isNull);
        await tester.tap(find.text('Continuar a líneas'));
        await tester.pumpAndSettle();
        expect(advance, findsNothing);
        final save = find.text('Guardar borrador').first;
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(api.savedAdvance, entry.value);
        await tester.tap(find.text('Atrás'));
        await tester.pumpAndSettle();
        expect(num.parse(tester.widget<TextField>(advance).controller!.text),
            entry.value);
        expect(tester.takeException(), isNull);
      }, () => MockClient((_) async => http.Response('{}', 200)));
    });
  }

  testWidgets('rejects malformed and out of range advances', (tester) async {
    await _pumpEditor(tester, _Api(0));
    for (final input in ['101', '1..2']) {
      await tester.enterText(advance, input);
      await tester.pump();
      expect(
          tester.widget<TextField>(advance).decoration!.errorText, isNotNull);
      await tester.tap(find.text('Continuar a líneas'));
      await tester.pumpAndSettle();
      expect(advance, findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
