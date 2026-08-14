import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/a-models/group_model/group/group.dart';
import 'package:hexora/a-models/group_model/worker/timeEntry.dart';
import 'package:hexora/a-models/group_model/worker/worker.dart';
import 'package:hexora/a-models/notification_model/notification_user.dart';
import 'package:hexora/a-models/user_model/user.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/repository/time_tracking_repository.dart';
import 'package:hexora/b-backend/notification/domain/notification_domain.dart';
import 'package:hexora/b-backend/user/domain/user_domain.dart';
import 'package:hexora/b-backend/user/repository/i_user_repository.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/workers/worker/entry_screen/tracking/controller/worker_time_tracking_controller.dart';

class _FakeTimeTrackingRepository implements ITimeTrackingRepository {
  double? lastTotalsAdvance;
  double? lastPreviewAdvance;

  @override
  Future<Map<String, dynamic>> getWorkerTotals(
    String groupId,
    String token, {
    String? workerId,
    DateTime? from,
    DateTime? to,
    double? advanceAmount,
  }) async {
    lastTotalsAdvance = advanceAmount;
    final gross = 200.0;
    final adv = (advanceAmount ?? 0).clamp(0, 999999).toDouble();
    final net = (gross - adv).clamp(0, gross).toDouble();
    return {
      'totalHours': 20.0,
      'grossPay': gross,
      'advanceAmount': adv,
      'netPay': net,
      'totalPay': gross,
      'currency': 'EUR',
    };
  }

  @override
  Future<Map<String, dynamic>> getActiveWorkersTotals(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    int? year,
    int? month,
  }) async {
    return {
      'period': {'from': null, 'to': null},
      'activeWorkersCount': 1,
      'entriesCount': 1,
      'totalMinutes': 60,
      'totalHours': 1.0,
      'totalPay': 10.0,
      'currency': 'EUR',
      'totalsByCurrency': const [
        {'currency': 'EUR', 'totalPay': 10.0}
      ],
    };
  }

  @override
  Future<Uint8List> previewPayrollPdf(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
    String? lang,
    double? advanceAmount,
  }) async {
    lastPreviewAdvance = advanceAmount;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  Future<Uint8List> exportMonthlyCalendarPdf(
    String groupId,
    String token, {
    required String month,
    String? workerId,
    String? lang,
    double? advanceAmount,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<TimeEntry>> getTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) async {
    return [
      TimeEntry(
        id: 'te-1',
        workerId: workerId ?? 'w-1',
        start: DateTime.utc(2026, 3, 1, 8),
        end: DateTime.utc(2026, 3, 1, 16),
      )
    ];
  }

  @override
  Future<Uint8List> exportExcel(String groupId, String token) =>
      throw UnimplementedError();

  @override
  Future<Uint8List> exportExcelFiltered(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> enable(String groupId, String token) =>
      throw UnimplementedError();

  @override
  Future<void> disable(String groupId, String token) =>
      throw UnimplementedError();

  @override
  Future<List<Worker>> getWorkers(String groupId, String token,
          {WorkerStatus? status}) =>
      throw UnimplementedError();

  @override
  Future<Worker> addWorker(String groupId, Worker worker, String token) =>
      throw UnimplementedError();

  @override
  Future<Worker> updateWorker(
          String groupId, String workerId, Worker worker, String token) =>
      throw UnimplementedError();

  @override
  Future<TimeEntry> createTimeEntry(
          String groupId, TimeEntry entry, String token) =>
      throw UnimplementedError();

  @override
  Future<TimeEntry> updateTimeEntry(
          String groupId, String entryId, TimeEntry entry, String token) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTimeEntry(String groupId, String entryId, String token) =>
      throw UnimplementedError();

  @override
  Future<int> purgeTimeEntries(
    String groupId,
    String token, {
    DateTime? from,
    DateTime? to,
    String? workerId,
  }) =>
      throw UnimplementedError();
}

class _FakeUserRepository implements IUserRepository {
  @override
  Future<String> getAuthToken({bool forceRefresh = false}) async => 'token';

  @override
  Future<User> createUser(User user) => throw UnimplementedError();
  @override
  Future<void> deleteUser(String id) => throw UnimplementedError();
  @override
  Future<List<User>> getAllUsers() => throw UnimplementedError();
  @override
  Future<String> getFreshAvatarUrl({required String blobName}) =>
      throw UnimplementedError();
  @override
  Future<User> getUserByAuthID(String authID) => throw UnimplementedError();
  @override
  Future<User> getUserByEmail(String email) => throw UnimplementedError();
  @override
  Future<User> getUserById(String id) => throw UnimplementedError();
  @override
  Future<User> getUserBySelector(String selector) => throw UnimplementedError();
  @override
  Future<User> getUserByUsername(String username) => throw UnimplementedError();
  @override
  Future<List<User>> getUsersByIds(List<String> ids) =>
      throw UnimplementedError();
  @override
  Future<List<User>> getUsersForGroup(Group group) =>
      throw UnimplementedError();
  @override
  Future<List<NotificationUser>> getNotificationsByUser(String userName) =>
      throw UnimplementedError();
  @override
  Future<List<String>> searchUsernames(String query) =>
      throw UnimplementedError();
  @override
  Future<bool> setAutoStatementImportEnabled({required bool enabled}) =>
      throw UnimplementedError();
  @override
  Future<User> updateUser(User user) => throw UnimplementedError();
  @override
  Future<User> updateUserByUsername(String username, User user) =>
      throw UnimplementedError();
}

Group _group() => Group(
      id: 'g-1',
      name: 'Group',
      ownerId: 'u-1',
      userRoles: const {'u-1': 'owner'},
      userIds: const ['u-1'],
      createdTime: DateTime.utc(2026, 1, 1),
      description: 'desc',
    );

Worker _worker() => const Worker(
      id: 'w-1',
      groupId: 'g-1',
      status: WorkerStatus.active,
      displayName: 'Worker',
      currency: 'EUR',
      defaultHourlyRate: 10,
    );

void main() {
  group('WorkerTimeTrackingController advance', () {
    test('advance=0 keeps net equal to gross', () async {
      final repo = _FakeTimeTrackingRepository();
      final userDomain = UserDomain(
        userRepository: _FakeUserRepository(),
        notificationDomain: NotificationDomain(),
      );

      final c = WorkerTimeTrackingController(
        group: _group(),
        worker: _worker(),
        repo: repo,
        userDomain: userDomain,
        initialYear: 2026,
        initialMonth: 3,
      );

      await c.load();

      expect(c.totals?['grossPay'], 200.0);
      expect(c.totals?['advanceAmount'], 0.0);
      expect(c.totals?['netPay'], 200.0);
      expect(repo.lastTotalsAdvance, isNull);
    });

    test('advance=80 applies deduction and preview uses same value', () async {
      final repo = _FakeTimeTrackingRepository();
      final userDomain = UserDomain(
        userRepository: _FakeUserRepository(),
        notificationDomain: NotificationDomain(),
      );

      final c = WorkerTimeTrackingController(
        group: _group(),
        worker: _worker(),
        repo: repo,
        userDomain: userDomain,
      );

      await c.load();
      await c.setAdvanceAmount(80);
      await c.previewPayrollPdf(lang: 'es');

      expect(c.totals?['grossPay'], 200.0);
      expect(c.totals?['advanceAmount'], 80.0);
      expect(c.totals?['netPay'], 120.0);
      expect(repo.lastPreviewAdvance, 80.0);
    });

    test('advance > gross shows net as 0', () async {
      final repo = _FakeTimeTrackingRepository();
      final userDomain = UserDomain(
        userRepository: _FakeUserRepository(),
        notificationDomain: NotificationDomain(),
      );

      final c = WorkerTimeTrackingController(
        group: _group(),
        worker: _worker(),
        repo: repo,
        userDomain: userDomain,
      );

      await c.load();
      await c.setAdvanceAmount(500);

      expect(c.totals?['grossPay'], 200.0);
      expect(c.totals?['advanceAmount'], 500.0);
      expect(c.totals?['netPay'], 0.0);
    });
  });
}
