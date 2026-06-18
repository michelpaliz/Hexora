import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/client/client_api.dart';
import 'package:hexora/b-backend/statements/models/statement_entries_page.dart';
import 'package:hexora/b-backend/statements/statements_api.dart';
import 'package:hexora/c-frontend/ui-app/b-dashboard-section/sections/enable_banking/statements/statements_controller.dart';

class _FakeStatementsApi extends StatementsApi {
  _FakeStatementsApi({
    required this.batchIds,
    this.delayPerCall = const Duration(milliseconds: 20),
    this.pageSize = 100,
    this.totalPerBatch = 150,
  });

  final List<String> batchIds;
  final Duration delayPerCall;
  final int pageSize;
  final int totalPerBatch;

  int callCount = 0;
  int inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<List<Map<String, dynamic>>> listImports() async {
    return batchIds
        .map((id) => <String, dynamic>{'batchId': id})
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> batchEntriesPaged({
    required String batchId,
    required int page,
    required int size,
    int? year,
    String? dateFrom,
    String? dateTo,
    String? order,
  }) async {
    callCount += 1;
    inFlight += 1;
    if (inFlight > maxInFlight) maxInFlight = inFlight;

    await Future<void>.delayed(delayPerCall);

    final int count;
    if (page == 1) {
      count = pageSize;
    } else if (page == 2) {
      count = totalPerBatch - pageSize;
    } else {
      count = 0;
    }

    final entries = List<Map<String, dynamic>>.generate(
      count,
      (i) => <String, dynamic>{
        'id': '$batchId-p$page-$i',
        'date': '2026-03-01',
        'amount': 10,
      },
      growable: false,
    );

    inFlight -= 1;

    return <String, dynamic>{
      'entries': entries,
      'total': totalPerBatch,
    };
  }
}

class _FakeAggregatedStatementsApi extends StatementsApi {
  int aggregatedCalls = 0;
  int listImportsCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> listImports() async {
    listImportsCalls += 1;
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<StatementEntriesPage> fetchStatementEntries({
    required String groupId,
    int page = 1,
    int size = 50,
    String? cursor,
    int? year,
    DateTime? dateFrom,
    DateTime? dateTo,
    String amountType = 'all',
    double? minAmount,
    double? maxAmount,
    String sort = 'date_desc',
  }) async {
    aggregatedCalls += 1;
    return StatementEntriesPage(
      items: const [
        StatementEntry({'id': 'e1', 'amount': 10, 'date': '2026-03-01'}),
        StatementEntry({'id': 'e2', 'amount': -5, 'date': '2026-03-02'}),
      ],
      page: page,
      size: size,
      total: 2,
      totalPages: 1,
      nextCursor: null,
      timing: const StatementEntriesTiming(dbMs: 7, totalMs: 12),
    );
  }
}

void main() {
  test('aggregated path: first load uses one entries endpoint call', () async {
    final api = _FakeAggregatedStatementsApi();

    final c = StatementsController(
      api: api,
      clientsApi: ClientsApi(),
      groupId: 'g1',
      useAggregated: true,
    );

    await c.loadAllEntries();

    expect(api.aggregatedCalls, 1);
    expect(api.listImportsCalls, 0);
    expect(c.allEntries.length, 2);
    expect(c.allEntriesTotal, 2);
    expect(c.allEntriesPage, 1);
    expect(c.allEntriesSize, 50);
  });

  test('diagnostic: loadAllEntries fetches batches concurrently (capped)',
      () async {
    final api = _FakeStatementsApi(batchIds: const ['b1', 'b2']);

    final c = StatementsController(
      api: api,
      clientsApi: ClientsApi(),
      groupId: 'g1',
      useAggregated: false,
    );

    await c.loadAllEntries(size: 100, page: 1);

    // 2 batches * 2 pages each = 4 paged calls
    expect(api.callCount, 4);

    // >1 means concurrent requests; controller caps concurrency to avoid overload.
    expect(api.maxInFlight, greaterThan(1));
    expect(api.maxInFlight, lessThanOrEqualTo(3));

    // 150 entries per batch * 2 batches
    expect(c.allEntries.length, 300);
  });

  test('diagnostic: loadAllEntries publishes partial data before completion',
      () async {
    final api = _FakeStatementsApi(
      batchIds: const ['b1', 'b2', 'b3'],
      delayPerCall: const Duration(milliseconds: 40),
    );

    final c = StatementsController(
      api: api,
      clientsApi: ClientsApi(),
      groupId: 'g1',
      useAggregated: false,
    );

    final future = c.loadAllEntries(size: 100, page: 1);
    await Future<void>.delayed(const Duration(milliseconds: 55));

    // First pages should already be visible while remaining pages still load.
    expect(c.loadingAllEntries, isTrue);
    expect(c.allEntries.isNotEmpty, isTrue);

    await future;
    expect(c.loadingAllEntries, isFalse);
    expect(c.allEntries.length, 450);
  });
}
