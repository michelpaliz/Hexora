import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/geofenced_visit.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/time_tracking_api_client.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/widgets/geofenced_visits_view.dart';
import 'package:hexora/c-frontend/utils/location/geofenced_visit_tracking_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('team arrival payload', () {
    test('arrival without companions remains backward compatible', () {
      final json = _event('arrival').toJson();

      expect(json, isNot(contains('participantWorkerIds')));
    });

    test('arrival includes multiple unique companion worker ids', () {
      final json = _event(
        'arrival',
        participantWorkerIds: const <String>[
          'worker-2',
          'worker-3',
          'worker-2'
        ],
      ).toJson();

      expect(
        json['participantWorkerIds'],
        const <String>['worker-2', 'worker-3'],
      );
    });

    test('departure never sends companion worker ids', () {
      final json = _event(
        'departure',
        participantWorkerIds: const <String>['worker-2'],
      ).toJson();

      expect(json, isNot(contains('participantWorkerIds')));
    });
  });

  group('active worker selection', () {
    final lead = _worker('worker-1', userId: 'user-1', name: 'Michael');
    final companion = _worker('worker-2', userId: 'user-2', name: 'Alex');
    final duplicate = _worker('worker-2', userId: 'user-3', name: 'Duplicate');
    final archived = _worker(
      'worker-3',
      userId: 'user-3',
      name: 'Archived',
      status: WorkerStatus.archived,
    );

    test('lead worker is excluded and duplicate companions are removed', () {
      final choices = companionWorkerChoices(
        <Worker>[lead, companion, duplicate, archived],
        lead.id,
      );

      expect(choices.map((worker) => worker.id), const <String>['worker-2']);
    });

    test('manager without a linked Worker profile is not a tracker', () {
      expect(
        findCurrentActiveWorker(<Worker>[lead, companion], 'manager-user'),
        isNull,
      );
    });

    test('linked active Worker profile is selected by userId', () {
      expect(findCurrentActiveWorker(<Worker>[lead], 'user-1')?.id, 'worker-1');
    });
  });

  group('role-aware visit filters', () {
    final group = Group(
      id: 'group-1',
      name: 'Test',
      ownerId: 'owner-1',
      userRoles: const <String, String>{
        'admin-1': 'admin',
        'coadmin-1': 'co-admin',
        'worker-user': 'member',
      },
      userIds: const <String>[
        'owner-1',
        'admin-1',
        'coadmin-1',
        'worker-user',
      ],
      createdTime: DateTime.utc(2026),
      description: '',
    );

    test('owner, admin and co-admin can use the worker filter', () {
      expect(canManageWorkerVisits(group, 'owner-1'), isTrue);
      expect(canManageWorkerVisits(group, 'admin-1'), isTrue);
      expect(canManageWorkerVisits(group, 'coadmin-1'), isTrue);
    });

    test('regular worker never sends another workerId', () {
      expect(canManageWorkerVisits(group, 'worker-user'), isFalse);
      expect(visitWorkerFilterId(false, 'worker-2'), isNull);
    });

    test('manager sends the selected workerId', () {
      expect(visitWorkerFilterId(true, 'worker-2'), 'worker-2');
      expect(visitWorkerFilterId(true, null), isNull);
    });

    test('empty-state copy is role specific', () {
      expect(
        visitEmptyStateCopy(true, true).title,
        'No hay visitas en este periodo.',
      );
      expect(
        visitEmptyStateCopy(false, true).title,
        'No tienes visitas en este periodo.',
      );
      expect(
        visitEmptyStateCopy(false, true).message,
        contains('acompa\u00f1ante'),
      );
    });

    testWidgets('manager sees worker dropdown and all-workers option',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitWorkerFilter(
              canManage: true,
              workers: <Worker>[
                _worker('worker-1', userId: 'user-1', name: 'Michael'),
              ],
              selectedWorkerId: null,
              isSpanish: true,
              decoration: const InputDecoration(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(
          find.byKey(const ValueKey('manager-worker-filter')), findsOneWidget);
      expect(find.text('Todos los trabajadores'), findsOneWidget);
      expect(find.text('Mis visitas'), findsNothing);
    });

    testWidgets('regular worker sees only my-visits filter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VisitWorkerFilter(
              canManage: false,
              workers: const <Worker>[],
              selectedWorkerId: 'worker-2',
              isSpanish: true,
              decoration: const InputDecoration(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('my-visits-filter')), findsOneWidget);
      expect(find.text('Mis visitas'), findsOneWidget);
      expect(find.byKey(const ValueKey('manager-worker-filter')), findsNothing);
    });
  });

  group('visit response', () {
    test('parses responsible worker, companions and backend duration only', () {
      final visit = WorkerVisit.fromJson(<String, dynamic>{
        '_id': 'visit-1',
        'clientId': <String, dynamic>{
          '_id': 'client-1',
          'name': 'Las Alondras Playa',
        },
        'workerId': <String, dynamic>{
          '_id': 'worker-1',
          'displayName': 'Michael',
          'userId': 'user-1',
        },
        'participantWorkerIds': <Map<String, dynamic>>[
          <String, dynamic>{
            '_id': 'worker-2',
            'displayName': 'Alex',
            'userId': 'user-2',
          },
          <String, dynamic>{
            '_id': 'worker-3',
            'displayName': 'Sara',
            'userId': 'user-3',
          },
        ],
        'recordedByUserId': 'user-1',
        'arrivedAt': '2026-09-08T08:00:00Z',
        'departedAt': '2026-09-08T09:00:00Z',
      });

      expect(visit.workerId, 'worker-1');
      expect(visit.workerName, 'Michael');
      expect(visit.clientId, 'client-1');
      expect(visit.clientName, 'Las Alondras Playa');
      expect(
        visit.participantWorkers.map((worker) => worker.displayName),
        <String?>['Alex', 'Sara'],
      );
      expect(visit.teamSize, 3);
      expect(visit.durationMinutes, isNull);
    });

    test('history keeps workerId filter when selected worker is a companion',
        () async {
      late http.Request captured;
      final api = TimeTrackingApiClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'visits': <Map<String, dynamic>>[
                <String, dynamic>{
                  '_id': 'visit-1',
                  'clientId': 'client-1',
                  'workerId': <String, dynamic>{
                    '_id': 'worker-1',
                    'displayName': 'Michael',
                  },
                  'participantWorkerIds': <Map<String, dynamic>>[
                    <String, dynamic>{
                      '_id': 'worker-2',
                      'displayName': 'Alex',
                    },
                  ],
                },
              ],
            }),
            200,
          );
        }),
      );

      final visits = await api.getWorkerVisits(
        'group-1',
        'token',
        workerId: 'worker-2',
      );

      expect(captured.url.queryParameters['workerId'], 'worker-2');
      expect(visits.single.participantWorkers.single.id, 'worker-2');
    });
  });

  group('visit status and duration', () {
    test('explicit status wins over departure inference', () {
      final activeWithDeparture = WorkerVisit(
        id: 'active',
        clientId: 'client-1',
        status: 'active',
        arrivedAt: DateTime.utc(2026, 9, 8, 8),
        departedAt: DateTime.utc(2026, 9, 8, 9),
      );
      final completedWithoutDeparture = WorkerVisit(
        id: 'completed',
        clientId: 'client-1',
        status: 'completed',
        arrivedAt: DateTime.utc(2026, 9, 8, 8),
      );

      expect(workerVisitIsActive(activeWithDeparture), isTrue);
      expect(workerVisitIsCompleted(activeWithDeparture), isFalse);
      expect(workerVisitIsActive(completedWithoutDeparture), isFalse);
      expect(workerVisitIsCompleted(completedWithoutDeparture), isTrue);
    });

    test('active duration updates and completed duration uses timestamps', () {
      final active = WorkerVisit(
        id: 'active',
        clientId: 'client-1',
        status: 'active',
        arrivedAt: DateTime.utc(2026, 9, 8, 8),
      );
      final completed = WorkerVisit(
        id: 'completed',
        clientId: 'client-1',
        status: 'completed',
        arrivedAt: DateTime.utc(2026, 9, 8, 8),
        departedAt: DateTime.utc(2026, 9, 8, 9, 15),
      );

      expect(
        workerVisitDuration(active, DateTime.utc(2026, 9, 8, 8, 45)),
        const Duration(minutes: 45),
      );
      expect(
        workerVisitDuration(completed, DateTime.utc(2030)),
        const Duration(minutes: 75),
      );
    });

    test('selected final local day is included through next midnight', () {
      final range = inclusiveLocalVisitRangeToUtc(
        DateTime(2026, 9, 1, 18),
        DateTime(2026, 9, 30, 10),
      );

      expect(range.start, DateTime(2026, 9, 1).toUtc());
      expect(range.end, DateTime(2026, 10, 1).toUtc());
    });
  });

  testWidgets('team badge opens responsible and companion details',
      (tester) async {
    const visit = WorkerVisit(
      id: 'visit-1',
      clientId: 'client-1',
      workerId: 'worker-1',
      workerName: 'Michael',
      participantWorkers: <VisitWorkerSummary>[
        VisitWorkerSummary(id: 'worker-2', displayName: 'Alex'),
      ],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VisitTeamBadge(visit: visit, isSpanish: true),
        ),
      ),
    );

    await tester.tap(find.text('2 trabajadores'));
    await tester.pumpAndSettle();

    expect(find.text('Equipo de la visita'), findsOneWidget);
    expect(find.textContaining('Michael'), findsOneWidget);
    expect(find.textContaining('Alex'), findsOneWidget);
  });

  group('backend validation messages', () {
    const cases = <String, String>{
      'INVALID_VISIT_PARTICIPANT':
          'Uno de los acompa\u00f1antes ya no es un trabajador activo.',
      'WORKER_ACTIVE_VISIT_EXISTS':
          'Uno de los trabajadores seleccionados ya participa en otra visita activa.',
      'ACTIVE_VISIT_EXISTS': 'Ya participas en otra visita activa.',
      'WORKER_PROFILE_REQUIRED':
          'Tu usuario todav\u00eda no est\u00e1 vinculado a un trabajador activo.',
    };

    for (final entry in cases.entries) {
      test(entry.key, () {
        final error = BackendApiException(
          statusCode: entry.key == 'INVALID_VISIT_PARTICIPANT' ? 400 : 409,
          code: entry.key,
          message: 'Backend message',
        );
        expect(visitTrackingErrorMessage(error), entry.value);
      });
    }

    test('visit history recognizes WORKER_PROFILE_REQUIRED separately', () {
      const error = BackendApiException(
        statusCode: 403,
        code: 'WORKER_PROFILE_REQUIRED',
        message: 'Backend message',
      );
      expect(isWorkerProfileRequiredError(error), isTrue);
      expect(
        workerProfileRequiredMessage(true),
        'Tu usuario no est\u00e1 vinculado a un trabajador activo. Contacta con un administrador.',
      );
    });
  });

  test('active worker endpoint sends status=active', () async {
    late http.Request captured;
    final api = TimeTrackingApiClient(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode(<Map<String, dynamic>>[
            <String, dynamic>{
              '_id': 'worker-1',
              'groupId': 'group-1',
              'userId': 'user-1',
              'displayName': 'Michael',
              'status': 'active',
            },
          ]),
          200,
        );
      }),
    );

    final workers = await api.listWorkers(
      'group-1',
      'token',
      status: WorkerStatus.active,
    );

    expect(captured.url.queryParameters['status'], 'active');
    expect(workers.single.userId, 'user-1');
  });
}

LocationBoundaryEvent _event(
  String eventType, {
  List<String> participantWorkerIds = const <String>[],
}) =>
    LocationBoundaryEvent(
      trackingSessionId: 'session-1',
      eventId: 'event-1',
      clientId: 'client-1',
      eventType: eventType,
      latitude: 38.8,
      longitude: -0.1,
      accuracyMeters: 10,
      recordedAt: DateTime.utc(2026, 9, 8, 8),
      source: 'foreground',
      participantWorkerIds: participantWorkerIds,
    );

Worker _worker(
  String id, {
  required String userId,
  required String name,
  WorkerStatus status = WorkerStatus.active,
}) =>
    Worker(
      id: id,
      groupId: 'group-1',
      userId: userId,
      displayName: name,
      status: status,
    );
