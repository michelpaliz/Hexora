import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/time_tracking_api_client.dart';

void main() {
  group('TimeTrackingApiClient.buildActiveWorkersTotalsUri', () {
    final api = TimeTrackingApiClient();

    test('without filters sends no query params', () {
      final uri = api.buildActiveWorkersTotalsUri('g1');
      expect(
          uri.path, contains('/groups/g1/time-tracking/totals/active-workers'));
      expect(uri.queryParameters, isEmpty);
    });

    test('year-month filter includes year and month', () {
      final uri = api.buildActiveWorkersTotalsUri(
        'g1',
        year: 2026,
        month: 3,
      );
      expect(uri.queryParameters['year'], '2026');
      expect(uri.queryParameters['month'], '3');
    });

    test('custom range includes from and to', () {
      final from = DateTime.utc(2026, 3, 1);
      final to = DateTime.utc(2026, 3, 31, 23, 59, 59);
      final uri = api.buildActiveWorkersTotalsUri('g1', from: from, to: to);

      expect(uri.queryParameters['from'], from.toIso8601String());
      expect(uri.queryParameters['to'], to.toIso8601String());
    });
  });
}
