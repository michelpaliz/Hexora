import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryTokenStore implements TokenStore {
  _MemoryTokenStore(this.tokens);

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
  _FakeAuthApiClient(this._refresh);

  final Future<Map<String, dynamic>> Function(String refreshToken) _refresh;
  int refreshCalls = 0;

  @override
  Future<Map<String, dynamic>> refresh({required String refreshToken}) {
    refreshCalls++;
    return _refresh(refreshToken);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MemoryTokenStore tokenStore;
  late _FakeAuthApiClient authApi;
  late int sessionExpiredCalls;

  setUp(() {
    tokenStore = _MemoryTokenStore(
      AuthTokens(access: 'old-access', refresh: 'refresh-token'),
    );
    authApi = _FakeAuthApiClient(
      (_) async => <String, dynamic>{
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh-token',
      },
    );
    sessionExpiredCalls = 0;
    AuthenticatedHttpClient.setTokenStoreForTesting(tokenStore);
    AuthenticatedHttpClient.setAuthApiClientForTesting(authApi);
    AuthenticatedHttpClient.setSessionExpiredHandlerForTesting(() async {
      sessionExpiredCalls++;
    });
  });

  tearDown(() {
    AuthenticatedHttpClient.setTokenStoreForTesting(null);
    AuthenticatedHttpClient.setAuthApiClientForTesting(null);
    AuthenticatedHttpClient.setSessionExpiredHandlerForTesting(null);
  });

  test('returns successful requests without refreshing', () async {
    http.Request? request;
    final response = await AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/success'),
      client: MockClient((value) async {
        request = value;
        return http.Response('', 200);
      }),
    );

    expect(response.statusCode, 200);
    expect(request!.headers['authorization'], 'Bearer old-access');
    expect(authApi.refreshCalls, 0);
    expect(sessionExpiredCalls, 0);
  });

  test('refreshes after a 401 and retries with the new access token', () async {
    final authorizationHeaders = <String?>[];
    final response = await AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/retry'),
      client: MockClient((request) async {
        authorizationHeaders.add(request.headers['authorization']);
        return http.Response('', authorizationHeaders.length == 1 ? 401 : 200);
      }),
    );

    expect(response.statusCode, 200);
    expect(authApi.refreshCalls, 1);
    expect(authorizationHeaders, ['Bearer old-access', 'Bearer new-access']);
    expect(tokenStore.tokens!.access, 'new-access');
    expect(tokenStore.tokens!.refresh, 'new-refresh-token');
    expect(sessionExpiredCalls, 0);
  });

  test('notifies session expiry when refresh fails', () async {
    authApi = _FakeAuthApiClient(
      (_) async => <String, dynamic>{'_status': 401, '_error': true},
    );
    AuthenticatedHttpClient.setAuthApiClientForTesting(authApi);
    var requests = 0;

    final response = await AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/refresh-failure'),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 401);
      }),
    );

    expect(response.statusCode, 401);
    expect(requests, 1);
    expect(authApi.refreshCalls, 1);
    expect(sessionExpiredCalls, 1);
  });

  test('notifies session expiry when the retry also receives a 401', () async {
    var requests = 0;
    final response = await AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/repeated-401'),
      client: MockClient((_) async {
        requests++;
        return http.Response('', 401);
      }),
    );

    expect(response.statusCode, 401);
    expect(requests, 2);
    expect(authApi.refreshCalls, 1);
    expect(sessionExpiredCalls, 1);
  });

  test('shares one refresh across concurrent 401 responses', () async {
    final initialRequests = Completer<void>();
    final refreshStarted = Completer<void>();
    final releaseRefresh = Completer<void>();
    authApi = _FakeAuthApiClient((_) async {
      if (!refreshStarted.isCompleted) refreshStarted.complete();
      await releaseRefresh.future;
      return <String, dynamic>{'accessToken': 'new-access'};
    });
    AuthenticatedHttpClient.setAuthApiClientForTesting(authApi);
    final authorizationHeaders = <String?>[];
    var oldAccessRequests = 0;
    final client = MockClient((request) async {
      authorizationHeaders.add(request.headers['authorization']);
      if (request.headers['authorization'] == 'Bearer old-access') {
        oldAccessRequests++;
        if (oldAccessRequests == 2) initialRequests.complete();
        return http.Response('', 401);
      }
      return http.Response(
        '',
        200,
      );
    });

    final first = AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/concurrent/one'),
      client: client,
    );
    final second = AuthenticatedHttpClient.get(
      Uri.parse('https://example.test/concurrent/two'),
      client: client,
    );
    await initialRequests.future;
    await refreshStarted.future;
    releaseRefresh.complete();

    final responses = await Future.wait([first, second]);

    expect(responses.map((response) => response.statusCode), everyElement(200));
    expect(authApi.refreshCalls, 1);
    expect(
      authorizationHeaders.where((header) => header == 'Bearer old-access'),
      hasLength(2),
    );
    expect(
      authorizationHeaders.where((header) => header == 'Bearer new-access'),
      hasLength(2),
    );
    expect(sessionExpiredCalls, 0);
  });
}
