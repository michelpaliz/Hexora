import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/navigation/shell/worker_status_indicator.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/theme/themes/app_theme.dart';
import 'package:provider/provider.dart';

Future<void> _pumpIndicator(
  WidgetTester tester, {
  required PresenceDomain presence,
  List<String> memberIds = const ['one', 'two'],
}) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<PresenceDomain>.value(
      value: presence,
      child: MaterialApp(
        theme: AppTheme.forPlatform(
          Brightness.light,
          platform: TargetPlatform.windows,
        ),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: WorkerStatusIndicator(
              memberIds: memberIds,
              groupRoles: const {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows unavailable state until presence is received',
      (tester) async {
    final presence = PresenceDomain();
    addTearDown(presence.dispose);

    await _pumpIndicator(tester, presence: presence);

    expect(find.text('—'), findsOneWidget);
    expect(find.byTooltip('Usuarios conectados'), findsOneWidget);
  });

  testWidgets('shows the connected member count', (tester) async {
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    presence.updatePresenceList([
      {'userId': 'one', 'userName': 'Ana'},
    ]);

    await _pumpIndicator(tester, presence: presence);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('—'), findsNothing);
  });

  testWidgets('only counts users belonging to the selected group',
      (tester) async {
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    presence.updatePresenceList([
      {'userId': 'one', 'userName': 'Ana'},
      {'userId': 'outside', 'userName': 'Luis'},
    ]);

    await _pumpIndicator(tester, presence: presence);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsNothing);
  });
}
