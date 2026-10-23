import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/presentation/screens/workspace/sections/enable_banking/statements/shared/statements_ai_match_suggest_dialog.dart';
import 'package:hexora/theme/themes/app_theme.dart';

void main() {
  Map<String, dynamic> suggestion() => <String, dynamic>{
        'suggestionId': 'suggestion-1',
        'rank': 1,
        'score': 0.92,
        'matchType': 'combination',
        'totalAmount': 1234.56,
        'targetAmount': 1200.0,
        'counterpartyName': 'Cliente de prueba con un nombre muy largo',
        'reasons': <String>['amount_match', 'same_client', 'date_close'],
        'ai': <String, dynamic>{
          'confidence': 0.61,
          'rationale':
              'El importe coincide y el cliente aparece en la descripción del banco.',
          'flags': <String>['low_confidence'],
        },
        'documents': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'invoice-1',
            'documentNumber': 'F-2026-0001',
            'issueDate': '2026-01-10',
            'total': 600.0,
            'currency': 'EUR',
            'counterpartyName': 'Cliente de prueba',
          },
          <String, dynamic>{
            'id': 'invoice-2',
            'documentNumber': 'F-2026-0002',
            'issueDate': '2026-01-11',
            'total': 634.56,
            'currency': 'EUR',
            'alreadyLinked': true,
          },
        ],
        'apply': <String, dynamic>{
          'supported': true,
          'body': <String, dynamic>{
            'invoiceIds': <String>['invoice-1', 'invoice-2'],
          },
        },
      };

  Future<void> pumpCard(
    WidgetTester tester, {
    required Brightness brightness,
    required Size size,
    bool expanded = false,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forPlatform(
          brightness,
          platform: TargetPlatform.android,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Builder(
              builder: (context) =>
                  StatementsAiMatchSuggestDialog.buildSuggestionCardForTest(
                context,
                suggestion: suggestion(),
                isExpanded: expanded,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    for (final size in const <Size>[
      Size(320, 900),
      Size(390, 900),
      Size(720, 900),
    ]) {
      testWidgets(
        'suggestion card fits ${brightness.name} at ${size.width}px',
        (tester) async {
          await pumpCard(
            tester,
            brightness: brightness,
            size: size,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('F-2026-0001 · F-2026-0002'), findsOneWidget);
          expect(find.text('Confianza divergente'), findsOneWidget);
          expect(find.text('Importe coincidente'), findsOneWidget);
          expect(find.text('Mismo cliente'), findsOneWidget);
          expect(find.text('Fecha cercana'), findsOneWidget);
          expect(find.text('Ver detalles y explicación'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('suggestion card handles 2x text at 320px', (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.dark,
      size: const Size(320, 1400),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('F-2026-0001 · F-2026-0002'), findsOneWidget);
  });

  testWidgets('expanded suggestion shows documents and AI explanation',
      (tester) async {
    await pumpCard(
      tester,
      brightness: Brightness.dark,
      size: const Size(390, 1200),
      expanded: true,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Documentos incluidos'), findsOneWidget);
    expect(find.text('F-2026-0001'), findsOneWidget);
    expect(find.text('F-2026-0002'), findsOneWidget);
    expect(find.text('Motivos'), findsOneWidget);
    expect(find.text('Explicación IA'), findsOneWidget);
    expect(find.text('Ya vinculado'), findsOneWidget);
  });
}
