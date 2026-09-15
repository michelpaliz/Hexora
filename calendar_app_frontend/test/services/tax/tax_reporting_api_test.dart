import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/auth/token/authenticated_http_client.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:hexora/services/auth/token/token_store.dart';
import 'package:hexora/services/tax/tax_reporting_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test-token'});
    TokenService.configureStore(SecureTokenStore());
  });

  Future<Map<String, dynamic>> load(
          TaxReportingApi api, TaxReportSection section) =>
      api.getReport(
        groupId: 'active-group',
        section: section,
        from: DateTime(2026, 7, 1),
        inclusiveTo: DateTime(2026, 9, 30),
        year: 2026,
        quarter: 3,
      );

  test('inclusive calendar dates become exclusive dates across DST and years',
      () {
    expect(taxExclusiveEnd(DateTime(2026, 9, 30)), '2026-10-01');
    expect(taxExclusiveEnd(DateTime(2026, 3, 29)), '2026-03-30');
    expect(taxExclusiveEnd(DateTime(2026, 12, 31)), '2027-01-01');
    expect(taxExclusiveEnd(DateTime(2028, 2, 28)), '2028-02-29');
  });

  test(
      'all endpoints use active group and Bearer token; quarterly has separate filters',
      () async {
    final requests = <http.Request>[];
    final api = TaxReportingApi(client: MockClient((request) async {
      requests.add(request);
      return http.Response('{"totals":{}}', 200);
    }));
    for (final section in TaxReportSection.values) {
      await load(api, section);
      final request = requests.last;
      expect(request.url.path, '/api/tax/${section.endpoint}');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(
          request.url.queryParameters,
          section == TaxReportSection.quarterly
              ? {'groupId': 'active-group', 'year': '2026', 'quarter': 'T3'}
              : {
                  'groupId': 'active-group',
                  'from': '2026-07-01',
                  'to': '2026-10-01',
                  'currency': 'EUR'
                });
    }
  });

  test('401 invokes existing session-expired handler and preserves status',
      () async {
    var expired = false;
    AuthenticatedHttpClient.setSessionExpiredHandler(() async {
      expired = true;
    });
    addTearDown(
        () => AuthenticatedHttpClient.setSessionExpiredHandler(() async {}));
    final api = TaxReportingApi(
        client: MockClient((_) async => http.Response('{}', 401)));
    await expectLater(
        load(api, TaxReportSection.irpf),
        throwsA(isA<TaxReportingException>()
            .having((e) => e.statusCode, 'status', 401)));
    expect(expired, isTrue);
  });

  test('403 and 400 preserve status for UI handling', () async {
    for (final status in [400, 403]) {
      final api = TaxReportingApi(
          client: MockClient((_) async =>
              http.Response('{"message":"Invalid request"}', status)));
      await expectLater(
          load(api, TaxReportSection.irpf),
          throwsA(isA<TaxReportingException>()
              .having((e) => e.statusCode, 'status', status)));
    }
  });

  test('malformed success is an error, not a zero report', () async {
    final api = TaxReportingApi(
        client:
            MockClient((_) async => http.Response('<html>proxy</html>', 200)));
    await expectLater(load(api, TaxReportSection.irpf), throwsFormatException);
  });
}
