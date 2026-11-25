import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/presentation/shared/widgets/hexora_loading_view.dart';
import 'package:hexora/presentation/utils/logo/hexora_brand.dart';

void main() {
  testWidgets('shows the Hexora brand and localized loading copy',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(body: HexoraLoadingView()),
      ),
    );

    expect(find.byType(HexoraBrandIcon), findsOneWidget);
    expect(find.text('Bienvenido a Hexora'), findsOneWidget);
    expect(find.text('Preparando tu espacio de trabajo…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('supports custom loading copy and reduced motion',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: HexoraLoadingView(
            title: 'Hexora',
            message: 'Loading data',
          ),
        ),
      ),
    );

    expect(find.text('Hexora'), findsOneWidget);
    expect(find.text('Loading data'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .value,
      0.68,
    );
  });
}
