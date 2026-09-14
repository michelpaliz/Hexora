import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:hexora/b-backend/errorClases/error_classes/error_classes.dart';
import 'package:hexora/b-backend/group_mng_flow/group/api/group_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore({this.tokens});

  AuthTokens? tokens;

  @override
  Future<void> clear() async => tokens = null;

  @override
  Future<String?> readAccess() async => tokens?.access;

  @override
  Future<AuthTokens?> readBoth() async => tokens;

  @override
  Future<String?> readRefresh() async => tokens?.refresh;

  @override
  Future<void> save(AuthTokens value) async => tokens = value;
}

class _FakeAuthApiClient implements IAuthApiClient {
  _FakeAuthApiClient(this.refreshResponse);

  final Map<String, dynamic> refreshResponse;
  int refreshCalls = 0;

  @override
  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    refreshCalls++;
    return refreshResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MemoryTokenStore tokenStore;
  late _FakeAuthApiClient authApi;
  var expiredSessions = 0;

  setUp(() {
    tokenStore = _MemoryTokenStore(
      tokens: AuthTokens(access: 'old-access', refresh: 'refresh-token'),
    );
    authApi = _FakeAuthApiClient({
      'accessToken': 'new-access',
      'refreshToken': 'new-refresh-token',
    });
    TokenService.setStoreForTesting(tokenStore);
    AuthenticatedHttpClient.setAuthApiClientForTesting(authApi);
    AuthenticatedHttpClient.setSessionExpiredHandler(() async {
      expiredSessions++;
    });
  });

  tearDown(() {
    TokenService.setStoreForTesting(null);
    AuthenticatedHttpClient.setAuthApiClientForTesting(null);
    AuthenticatedHttpClient.setSessionExpiredHandler(() async {});
  });

  test(
    'retries a 401 group request with refreshed credentials and its payload',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('', requests.length == 1 ? 401 : 200);
      });
      final api = HttpGroupApiClient(client: client);

      await api.respondToInvite(
        groupId: 'group-1',
        userId: 'user-1',
        accepted: true,
        token: 'old-access',
      );

      expect(authApi.refreshCalls, 1);
      expect(expiredSessions, 0);
      expect(requests, hasLength(2));
      expect(requests.map((request) => request.method), everyElement('PUT'));
      expect(
        requests.map((request) => request.headers['authorization']),
        ['Bearer old-access', 'Bearer new-access'],
      );
      expect(
        requests.map((request) => jsonDecode(request.body)),
        [
          {'groupId': 'group-1', 'userId': 'user-1', 'accepted': true},
          {'groupId': 'group-1', 'userId': 'user-1', 'accepted': true},
        ],
      );
    },
  );

  test(
    'notifies session expiry and preserves the group client error on failed refresh',
    () async {
      authApi = _FakeAuthApiClient({'_status': 401, '_error': true});
      AuthenticatedHttpClient.setAuthApiClientForTesting(authApi);
      var requestCount = 0;
      final api = HttpGroupApiClient(
        client: MockClient((_) async {
          requestCount++;
          return http.Response('{"code":"SESSION_EXPIRED"}', 401);
        }),
      );

      await expectLater(
        api.getGroupsByUser('alex', 'old-access'),
        throwsA(
          isA<HttpFailure>()
              .having((error) => error.statusCode, 'statusCode', 401)
              .having(
                (error) => error.message,
                'message',
                '{"code":"SESSION_EXPIRED"}',
              ),
        ),
      );

      expect(authApi.refreshCalls, 1);
      expect(requestCount, 1);
      expect(expiredSessions, 1);
    },
  );
}
