import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_roles_card.dart';
import 'package:hexora/presentation/screens/calendar/screens/group/group-settings/widgets/group_overview_card.dart';
import 'package:hexora/l10n/app_localizations.dart';

void main() {
  testWidgets('group settings show names instead of database IDs',
      (tester) async {
    final group = Group(
        id: 'group',
        name: 'Jardinería',
        ownerId: 'secret-owner-id',
        userIds: const ['secret-owner-id', 'secret-member-id'],
        userRoles: const {
          'secret-owner-id': 'owner',
          'secret-member-id': 'co-admin'
        },
        description: 'Descripción',
        createdTime: DateTime(2026));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
        GroupOverviewCard(
            group: group,
            createdFormatted: '11 sept 2026',
            ownerName: 'Michael'),
        GroupRolesCard(
            group: group, memberNames: const {'secret-owner-id': 'Michael'}),
      ]))),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Michael'), findsNWidgets(2));
    expect(find.textContaining('secret-'), findsNothing);
    expect(find.text('Nombre no disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
