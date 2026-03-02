import 'dart:async';
import 'dart:convert';

import 'package:hexora/b-backend/auth_user/api/auth_api_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:http/http.dart' as http;

class AuthenticatedHttpClient {
  static final AuthApiClientImpl _authApi = AuthApiClientImpl();
  static Future<bool>? _refreshInFlight;

  static Future<Map<String, String>> authorizedHeaders({
    Map<String, String>? extra,
    bool includeJsonContentType = true,
  }) async {
    final token = await TokenService.loadToken();
    return <String, String>{
      if (includeJsonContentType)
        'Content-Type': 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  static Future<http.Response> get(
    Uri uri, {
    Map<String, String>? headers,
    http.Client? client,
  }) {
    return _request(
      method: 'GET',
      uri: uri,
      headers: headers,
      client: client,
    );
  }

  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    http.Client? client,
  }) {
    return _request(
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
      encoding: encoding,
      client: client,
    );
  }

  static Future<http.Response> patch(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    http.Client? client,
  }) {
    return _request(
      method: 'PATCH',
      uri: uri,
      headers: headers,
      body: body,
      encoding: encoding,
      client: client,
    );
  }

  static Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    http.Client? client,
  }) {
    return _request(
      method: 'PUT',
      uri: uri,
      headers: headers,
      body: body,
      encoding: encoding,
      client: client,
    );
  }

  static Future<http.Response> delete(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    http.Client? client,
  }) {
    return _request(
      method: 'DELETE',
      uri: uri,
      headers: headers,
      body: body,
      encoding: encoding,
      client: client,
    );
  }

  static Future<http.Response> _request({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    http.Client? client,
  }) async {
    final mergedHeaders = await authorizedHeaders(extra: headers);
    final c = client ?? http.Client();
    final ownsClient = client == null;
    try {
      var response = await _dispatch(
        c,
        method: method,
        uri: uri,
        headers: mergedHeaders,
        body: body,
        encoding: encoding,
      );
      if (response.statusCode != 401) return response;

      final refreshed = await _refreshAccessToken();
      if (!refreshed) return response;

      final retryHeaders = await authorizedHeaders(extra: headers);
      response = await _dispatch(
        c,
        method: method,
        uri: uri,
        headers: retryHeaders,
        body: body,
        encoding: encoding,
      );
      return response;
    } finally {
      if (ownsClient) {
        c.close();
      }
    }
  }

  static Future<http.Response> _dispatch(
    http.Client client, {
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
    Encoding? encoding,
  }) {
    switch (method) {
      case 'GET':
        return client.get(uri, headers: headers);
      case 'POST':
        return client.post(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'PATCH':
        return client.patch(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'PUT':
        return client.put(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
      case 'DELETE':
        return client.delete(
          uri,
          headers: headers,
          body: body,
          encoding: encoding,
        );
    }
    throw UnsupportedError('Unsupported HTTP method: $method');
  }

  static Future<bool> _refreshAccessToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final completer = Completer<bool>();
    _refreshInFlight = completer.future;
    try {
      final refreshToken = await TokenService.loadRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(false);
        return false;
      }
      final data = await _authApi.refresh(refreshToken: refreshToken);
      final status = data['_status'] as int? ?? 200;
      if (status < 200 || status >= 300 || data['_error'] == true) {
        completer.complete(false);
        return false;
      }
      final newAccess =
          (data['accessToken'] ?? data['access_token'])?.toString().trim();
      if (newAccess == null || newAccess.isEmpty) {
        completer.complete(false);
        return false;
      }
      final newRefresh =
          (data['refreshToken'] ?? data['refresh_token'])?.toString().trim() ??
              refreshToken;
      await TokenService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      completer.complete(true);
      return true;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshInFlight = null;
    }
  }
}
