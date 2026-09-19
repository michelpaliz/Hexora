import 'dart:convert';
import 'package:hexora/presentation/routes/app_routes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/insights_chat_fab.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final hasHistory in [false, true]) {
    for (final brightness in Brightness.values) {
      testWidgets('chat mobile $brightness history=$hasHistory',
          (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final group = '$brightness-$hasHistory';
        SharedPreferences.setMockInitialValues({
          if (hasHistory)
            'insights_chat_history::anon::fab::$group': jsonEncode([
              {
                'isUser': false,
                'text': 'Estos son los movimientos del periodo.',
                'timestamp': '2026-09-12T08:00:00Z',
                'view': 'table',
                'table': {
                  'columns': [
                    {'key': 'date', 'label': 'Fecha'},
                    {'key': 'concept', 'label': 'Concepto'},
                    {'key': 'amount', 'label': 'Importe'},
                  ],
                  'rows': [
                    {
                      'date': '12/09/2026',
                      'concept': 'Mantenimiento',
                      'amount': 120
                    },
                  ],
                },
                'menu': {
                  'options': [
                    for (var i = 1; i <= 4; i++)
                      {
                        'index': i,
                        'label':
                            'Opción $i: Ver todos los movimientos de este periodo y comparar las facturas pendientes.'
                      },
                  ],
                },
              },
            ]),
        });
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.forPlatform(brightness,
              platform: TargetPlatform.android),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          initialRoute: AppRoutes.groupDashboard,
          routes: {
            AppRoutes.groupDashboard: (_) =>
                Scaffold(floatingActionButton: InsightsChatFab(groupId: group))
          },
        ));
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(TextField), findsOneWidget);
        if (hasHistory) {
          await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
          await tester.pumpAndSettle();
          expect(find.byType(DataTable), findsOneWidget);
          final tableScroll = find
              .ancestor(
                of: find.byType(DataTable),
                matching: find.byType(SingleChildScrollView),
              )
              .first;
          await tester.drag(tableScroll, const Offset(-220, 0));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.drag(find.byType(ListView).first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byType(TextField));
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getBottomLeft(find.byType(TextField)).dy,
            lessThanOrEqualTo(400));
        await tester.enterText(find.byType(TextField),
            'Un mensaje largo para comprobar el campo de texto en un móvil pequeño.');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        tester.view.physicalSize = const Size(700, 400);
        tester.view.viewInsets = const FakeViewPadding(bottom: 160);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getBottomLeft(find.byType(TextField)).dy,
            lessThanOrEqualTo(240));
        tester.view.viewInsets = const FakeViewPadding();
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
      });
    }
  }
}
