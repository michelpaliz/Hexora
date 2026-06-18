import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/time_tracking_api_client.dart';

void main() {
  group('TimeTrackingApiClient.buildMonthlyPayrollHistoryUri', () {
    final api = TimeTrackingApiClient();

    test('includes from and to', () {
      final from = DateTime.utc(2025, 1, 1);
      final to = DateTime.utc(2026, 1, 1);
      final uri = api.buildMonthlyPayrollHistoryUri(
        'g1',
        from: from,
        to: to,
      );

      expect(uri.path, contains('/groups/g1/time-tracking/totals/history'));
      expect(uri.queryParameters['from'], from.toIso8601String());
      expect(uri.queryParameters['to'], to.toIso8601String());
    });

    test('includes workerId when provided', () {
      final uri = api.buildMonthlyPayrollHistoryUri(
        'g1',
        from: DateTime.utc(2025, 1, 1),
        to: DateTime.utc(2026, 1, 1),
        workerId: 'w123',
      );
      expect(uri.queryParameters['workerId'], 'w123');
    });
  });
}
