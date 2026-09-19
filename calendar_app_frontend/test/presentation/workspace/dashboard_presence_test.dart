import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/services/user/presence_domain.dart';
import 'package:hexora/presentation/screens/workspace/dashboard/header/widgets/dashboard_presence_strip.dart';
import 'package:hexora/presentation/shared/widgets/avatars/pulsing_ring_avatar.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets(
      'dashboard reacts to online group members and respects reduced motion',
      (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final presence = PresenceDomain();
    addTearDown(presence.dispose);
    final group = Group(
        id: 'group',
        name: 'Business',
        ownerId: 'one',
        userIds: ['two'],
        userRoles: {},
        createdTime: DateTime(2026),
        description: '');
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: presence,
        child: MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  disableAnimations: true,
                  textScaler: const TextScaler.linear(2)),
              child: child!),
          home: Scaffold(body: DashboardPresenceStrip(group: group)),
        )));
    await tester.pumpAndSettle();
    expect(find.byType(PulsingRingAvatar), findsNothing);
    expect(find.text('Esperando estado de conexión…'), findsOneWidget);
    presence.updatePresenceList([
      null,
      {'userName': 'Missing ID'},
      {'userId': 'one', 'userName': 'Michael', 'photoUrl': null},
      {'userId': 'outsider', 'userName': 'Other group', 'photoUrl': ''},
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Michael'), findsOneWidget);
    expect(find.text('Other group'), findsNothing);
    expect(find.text('En línea (1)'), findsOneWidget);
    expect(
        tester
            .widget<PulsingRingAvatar>(find.byType(PulsingRingAvatar))
            .isOnline,
        isTrue);
    expect(tester.takeException(), isNull);
    presence.updatePresenceList([]);
    await tester.pumpAndSettle();
    expect(find.byType(PulsingRingAvatar), findsNothing);
    expect(find.text('No hay miembros en línea'), findsOneWidget);
  });
}
