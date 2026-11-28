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
  VoidCallback? onPressed,
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
              onPressed: onPressed ?? () {},
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

    expect(find.byTooltip('Miembros · estado no disponible'), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-members-online-indicator')),
        findsNothing);
  });

  testWidgets('shows the connected member count', (tester) async {
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    presence.updatePresenceList([
      {'userId': 'one', 'userName': 'Ana'},
    ]);

    await _pumpIndicator(tester, presence: presence);

    expect(find.byTooltip('Miembros · 1 conectados'), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-members-online-indicator')),
        findsOneWidget);
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

    expect(find.byTooltip('Miembros · 1 conectados'), findsOneWidget);
  });

  testWidgets('opens the members workspace when pressed', (tester) async {
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    var pressed = false;

    await _pumpIndicator(
      tester,
      presence: presence,
      onPressed: () => pressed = true,
    );
    await tester.tap(find.byKey(const ValueKey('workspace-members-button')));

    expect(pressed, isTrue);
  });
}
