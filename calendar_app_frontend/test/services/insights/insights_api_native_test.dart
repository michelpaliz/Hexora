import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/services/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/services/auth_user/auth/token/token_store/token_store.dart';
import 'package:hexora/services/insights/insights_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'test-token'});
    TokenService.configureStore(SecureTokenStore());
  });

  test('native auto chat sends authenticated HTTPS JSON without origin errors',
      () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(
          request.url.toString(), 'https://hexora.dev/api/insights/chat/auto');
      expect(request.headers['authorization'], 'Bearer test-token');
      expect(request.headers['accept'], 'application/json');
      expect(jsonDecode(request.body)['groupId'], 'group-1');
      return http.Response('{"reply":"Hello"}', 200);
    });
    addTearDown(client.close);

    final reply = await InsightsApi(client: client).chatAuto(
      message: 'Hello',
      groupId: 'group-1',
    );
    expect(reply.text, 'Hello');
  });

  for (final endpoint in {
    InsightsChatEndpoint.chatAutoStream: '/api/insights/chat/auto',
    InsightsChatEndpoint.chatStream: '/api/insights/chat',
  }.entries) {
    test(
        'native ${endpoint.key.name} uses JSON and preserves response metadata',
        () async {
      var requests = 0;
      final raw = {
        'reply': 'Report ready',
        'actions': [
          {
            'type': 'export_excel',
            'endpoint': '/api/insights/chat/export/excel'
          },
        ],
      };
      final client = MockClient((request) async {
        requests++;
        expect(request.url.path, endpoint.value);
        expect(request.url.scheme, 'https');
        expect(request.headers['accept'], 'application/json');
        expect(request.headers['authorization'], 'Bearer test-token');
        expect(jsonDecode(request.body), {
          'message': 'Create report',
          'groupId': 'group-1',
          'temperature': 0.4,
          'max_tokens': 900,
          'timeoutMs': 30000,
          'dateFrom': '2026-09-01',
          'dateTo': '2026-09-10',
        });
        return http.Response(jsonEncode(raw), 200);
      });
      addTearDown(client.close);

      final events = await InsightsApi(client: client).streamChat(
        endpoint: endpoint.key,
        message: 'Create report',
        groupId: 'group-1',
        temperature: 0.4,
        maxTokens: 900,
        timeoutMs: 30000,
        extra: {'dateFrom': '2026-09-01', 'dateTo': '2026-09-10'},
      ).toList();

      expect(requests, 1);
      expect(events, hasLength(1));
      expect(events.single.delta, 'Report ready');
      expect(events.single.raw, raw);
      expect(events.single.hasTimeout, isFalse);
    });
  }

  test('native stream fallback preserves timeout and retry information',
      () async {
    final client = MockClient((_) async => http.Response(
        jsonEncode({
          'code': 'INSIGHTS_TIMEOUT',
          'fallbackMessage': 'Try again shortly',
          'canRetry': true,
          'timeoutMs': 30000,
        }),
        504));
    addTearDown(client.close);

    final events = await InsightsApi(client: client)
        .streamChat(
          endpoint: InsightsChatEndpoint.chatAutoStream,
          message: 'Report',
          groupId: 'group-1',
        )
        .toList();
    expect(events.single.delta, 'Try again shortly');
    expect(events.single.timeout?.canRetry, isTrue);
    expect(events.single.timeout?.timeoutMs, 30000);
  });

  test('native stream fallback propagates API errors', () async {
    final client = MockClient((_) async => http.Response(
          '{"message":"Access denied","code":"FORBIDDEN"}',
          403,
        ));
    addTearDown(client.close);

    await expectLater(
      InsightsApi(client: client)
          .streamChat(
            endpoint: InsightsChatEndpoint.chatAutoStream,
            message: 'Report',
            groupId: 'group-1',
          )
          .toList(),
      throwsA(isA<InsightsApiException>()
          .having((error) => error.statusCode, 'statusCode', 403)
          .having((error) => error.code, 'code', 'FORBIDDEN')),
    );
  });
}
