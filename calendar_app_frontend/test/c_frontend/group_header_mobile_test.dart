import 'package:hexora/f-themes/app_colors/themes/context_colors/theme_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/dashboard_screen/header/widget/group_header_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('mobile summary wraps labeled counts and preserves actions',
      (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var edits = 0;
    var members = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2)),
          child: child!),
      home: Scaffold(
          body: SingleChildScrollView(
              child: Padding(
        padding: const EdgeInsets.all(16),
        child: GroupHeaderCard(
          photoUrl: null,
          title: 'Mantenimiento Michel SL',
          description:
              'Grupo para la empresa de jardinería. Una descripción larga que debe estar disponible completa, sin cortar las instrucciones del grupo.',
          createdLabel: 'Creado el 8 oct 2025',
          members: 4,
          pending: 0,
          total: 4,
          localeName: 'es',
          clientCount: 36,
          workerCount: 9,
          pendingEventsCount: 57,
          onTap: () => edits++,
          onMembersTap: () => members++,
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final description = tester.widget<Text>(find.text(
        'Grupo para la empresa de jardinería. Una descripción larga que debe estar disponible completa, sin cortar las instrucciones del grupo.'));
    expect(description.maxLines, isNull);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.ensureVisible(find.text('4 miembros'));
    await tester.tap(find.text('4 miembros'));
    expect(edits, 1);
    expect(members, 1);
  });
}
