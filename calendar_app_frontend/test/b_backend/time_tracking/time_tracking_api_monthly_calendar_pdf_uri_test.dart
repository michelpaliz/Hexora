import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/group_mng_flow/business_logic/worker/api/time_tracking_api_client.dart';

void main() {
  test('monthly calendar PDF URI includes the active report filters', () {
    final api = TimeTrackingApiClient();

    final uri = api.buildMonthlyCalendarPdfUri(
      'g1',
      month: '2026-07',
      workerId: 'w123',
      lang: 'es',
      advanceAmount: 100,
    );

    expect(
      uri.path,
      contains('/groups/g1/time-tracking/export/pdf/monthly-calendar'),
    );
    expect(uri.queryParameters, {
      'month': '2026-07',
      'workerId': 'w123',
      'lang': 'es',
      'advanceAmount': '100.00',
    });
  });
}
