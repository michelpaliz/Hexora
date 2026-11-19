import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/l10n/app_localizations.dart';
import 'package:hexora/models/groups/group.dart';
import 'package:hexora/models/workers/worker.dart';
import 'package:hexora/presentation/screens/workspace/sections/workers/widgets/worker_directory_tabs.dart';

void main() {
  test('partners use linked group roles, including the owner fallback', () {
    final group = Group(
      id: 'group',
      name: 'Team',
      ownerId: 'owner',
      userRoles: {
        'admin': 'admin',
        'co-admin': 'co-admin',
        'member': 'member',
      },
      userIds: [],
      createdTime: DateTime(2026),
      description: '',
    );
    Worker worker(String? userId) => Worker(
          id: 'worker',
          groupId: group.id,
          status: WorkerStatus.active,
          userId: userId,
          // A job label is not a group permission.
          roleTag: 'admin',
        );
    for (final id in ['owner', 'admin', 'co-admin']) {
      expect(isPartnerWorker(worker(id), group), isTrue);
    }
    for (final id in [null, '', 'member', 'unknown']) {
      expect(isPartnerWorker(worker(id), group), isFalse);
    }
    expect(
        partnerRoleForWorker(worker('owner'), group), WorkerPartnerRole.owner);
    expect(
        partnerRoleForWorker(worker('admin'), group), WorkerPartnerRole.admin);
    expect(partnerRoleForWorker(worker('co-admin'), group),
        WorkerPartnerRole.coAdmin);
    group.userRoles['owner'] = 'admin';
    expect(
        partnerRoleForWorker(worker('owner'), group), WorkerPartnerRole.owner);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('tabs switch both ways at narrow width, text scale $scale',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var partners = false;
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(builder: (context, setState) {
              return WorkerDirectoryTabs(
                showPartners: partners,
                workerCount: 12,
                partnerCount: 4,
                onChanged: (value) => setState(() => partners = value),
              );
            }),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Socios (4)'));
      await tester.pumpAndSettle();
      expect(partners, isTrue);
      await tester.tap(find.text('Trabajadores (12)'));
      await tester.pumpAndSettle();
      expect(partners, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
