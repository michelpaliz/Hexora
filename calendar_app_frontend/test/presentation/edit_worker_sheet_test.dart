import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/group/group.dart';
import 'package:hexora/models/worker/worker.dart';
import 'package:hexora/data/group_management/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/presentation/features/dashboard/sections/workers/worker/edit_worker/edit_worker_sheet.dart';
import 'package:hexora/theme/app_colors/themes/context_colors/theme_data.dart';
import 'package:hexora/l10n/app_localizations.dart';

class _FakeTimeTrackingRepository implements ITimeTrackingRepository {
  Worker? updatedWorker;

  @override
  Future<Worker> updateWorker(
    String groupId,
    String workerId,
    Worker worker,
    String token, {
    String? month,
    DateTime? from,
    DateTime? to,
  }) async {
    updatedWorker = worker;
    return worker;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Group _group() => Group(
      id: 'group-1',
      name: 'Group',
      ownerId: 'user-1',
      userRoles: const {'user-1': 'owner'},
      userIds: const ['user-1'],
      createdTime: DateTime.utc(2026, 1, 1),
      description: 'Test group',
    );

const _worker = Worker(
  id: 'worker-1',
  groupId: 'group-1',
  status: WorkerStatus.active,
  displayName: 'Ada',
  defaultHourlyRate: 42,
  roleTag: 'Engineer',
  notes: 'On call Fridays',
  currency: 'EUR',
);

void main() {
  testWidgets('clearing editable worker fields sends explicit nulls',
      (tester) async {
    final repo = _FakeTimeTrackingRepository();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EditWorkerSheet(
              group: _group(),
              worker: _worker,
              repo: repo,
              getToken: () async => 'token',
            ),
          ),
        ),
      ),
    );

    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      field.controller!.clear();
    }
    await tester.pump();

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    await tester.pumpAndSettle();

    expect(repo.updatedWorker, isNotNull);
    expect(repo.updatedWorker!.displayName, isNull);
    expect(repo.updatedWorker!.defaultHourlyRate, isNull);
    expect(repo.updatedWorker!.roleTag, isNull);
    expect(repo.updatedWorker!.notes, isNull);
    expect(repo.updatedWorker!.toUpdateJson(),
        containsPair('displayName', isNull));
    expect(
      repo.updatedWorker!.toUpdateJson(),
      containsPair('defaultHourlyRate', isNull),
    );
    expect(repo.updatedWorker!.toUpdateJson(), containsPair('roleTag', isNull));
    expect(repo.updatedWorker!.toUpdateJson(), containsPair('notes', isNull));
  });
}
