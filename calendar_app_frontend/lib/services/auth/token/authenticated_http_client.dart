import 'dart:async';
import 'dart:convert';

import 'package:hexora/services/auth/api/auth_api_client.dart';
import 'package:hexora/services/auth/token/token_service.dart';
import 'package:http/http.dart' as http;

class AuthenticatedHttpClient {
  static final AuthApiClientImpl _authApi = AuthApiClientImpl();
  static String _preferredLanguage = 'es';
  static Future<_RefreshResult>? _refreshInFlight;
  static Future<void> Function()? _onSessionExpired;
  static void Function(String feature, String? groupId)?
      _onPremiumFeatureRequired;

  static void setSessionExpiredHandler(Future<void> Function() handler) {
    _onSessionExpired = handler;
  }

  static void setPremiumFeatureRequiredHandler(
    void Function(String feature, String? groupId) handler,
  ) {
    _onPremiumFeatureRequired = handler;
  }

  static void setPreferredLanguage(String languageCode) {
    _preferredLanguage = languageCode == 'en' ? 'en' : 'es';
  }

  static String get preferredLanguageCode => _preferredLanguage;

  static Future<Map<String, String>> authorizedHeaders({
    Map<String, String>? extra,
    bool includeJsonContentType = true,
  }) async {
    final token = await TokenService.loadToken();
    return <String, String>{
      'Accept-Language': _preferredLanguage,
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

  /// Rebuilds multipart bodies for a retry because their streams are single-use.
  static Future<http.Response> sendMultipart(
    http.MultipartRequest Function(Map<String, String> headers) buildRequest,
  ) async {
    Future<http.Response> send(Map<String, String> headers) async {
      final request = buildRequest(headers);
      request.headers.addAll(headers);
      return http.Response.fromStream(await request.send());
    }

    var response = await send(
      await authorizedHeaders(includeJsonContentType: false),
    );
    if (response.statusCode != 401) {
      _notifyPremiumFeatureRequired(
        response,
        requestUri: response.request?.url,
      );
      return response;
    }

    final refreshResult = await _refreshAccessToken();
    if (refreshResult == _RefreshResult.invalidCredentials) {
      await _notifySessionExpired();
      return response;
    }
    if (refreshResult == _RefreshResult.temporaryFailure) return response;

    response = await send(
      await authorizedHeaders(includeJsonContentType: false),
    );
    if (response.statusCode == 401) {
      await _notifySessionExpired();
    } else {
      _notifyPremiumFeatureRequired(
        response,
        requestUri: response.request?.url,
      );
    }
    return response;
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
      if (response.statusCode != 401) {
        _notifyPremiumFeatureRequired(response, requestUri: uri, body: body);
        return response;
      }

      final refreshResult = await _refreshAccessToken();
      if (refreshResult == _RefreshResult.invalidCredentials) {
        await _notifySessionExpired();
        return response;
      }
      if (refreshResult == _RefreshResult.temporaryFailure) return response;

      final retryHeaders = await authorizedHeaders(extra: headers);
      response = await _dispatch(
        c,
        method: method,
        uri: uri,
        headers: retryHeaders,
        body: body,
        encoding: encoding,
      );
      if (response.statusCode == 401) {
        await _notifySessionExpired();
      } else {
        _notifyPremiumFeatureRequired(response, requestUri: uri, body: body);
      }
      return response;
    } finally {
      if (ownsClient) {
        c.close();
      }
    }
  }

  static Future<void> _notifySessionExpired() async {
    final cb = _onSessionExpired;
    if (cb == null) return;
    try {
      await cb();
    } catch (_) {}
  }

  static void _notifyPremiumFeatureRequired(
    http.Response response, {
    Uri? requestUri,
    Object? body,
  }) {
    if (response.statusCode != 403) return;
    try {
      final payload = jsonDecode(response.body);
      if (payload is! Map ||
          payload['code']?.toString() != 'PREMIUM_FEATURE_REQUIRED') {
        return;
      }
      final feature = payload['feature']?.toString().trim();
      if (feature == null || feature.isEmpty) return;
      final responseGroupId = payload['groupId']?.toString().trim();
      final groupId = responseGroupId?.isNotEmpty == true
          ? responseGroupId
          : _requestGroupId(requestUri, body);
      _onPremiumFeatureRequired?.call(feature, groupId);
    } catch (_) {
      // A normal authorization failure may not contain JSON.
    }
  }

  static String? _requestGroupId(Uri? uri, Object? body) {
    final queryValue = uri?.queryParameters['groupId']?.trim();
    if (queryValue?.isNotEmpty == true) return queryValue;
    if (uri != null) {
      final segments = uri.pathSegments;
      final groupIndex = segments.indexOf('groups');
      if (groupIndex >= 0 && groupIndex + 1 < segments.length) {
        final value = segments[groupIndex + 1].trim();
        if (value.isNotEmpty) return value;
      }
    }
    try {
      final payload = body is String ? jsonDecode(body) : body;
      if (payload is Map) {
        final value = payload['groupId']?.toString().trim();
        if (value?.isNotEmpty == true) return value;
      }
    } catch (_) {}
    return null;
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

  static Future<_RefreshResult> _refreshAccessToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final completer = Completer<_RefreshResult>();
    _refreshInFlight = completer.future;
    try {
      final refreshToken = await TokenService.loadRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        completer.complete(_RefreshResult.invalidCredentials);
        return _RefreshResult.invalidCredentials;
      }
      final data = await _authApi.refresh(refreshToken: refreshToken);
      final status = data['_status'] as int? ?? 200;
      if (status < 200 || status >= 300 || data['_error'] == true) {
        final result = status == 400 || status == 401 || status == 403
            ? _RefreshResult.invalidCredentials
            : _RefreshResult.temporaryFailure;
        completer.complete(result);
        return result;
      }
      final newAccess =
          (data['accessToken'] ?? data['access_token'])?.toString().trim();
      if (newAccess == null || newAccess.isEmpty) {
        completer.complete(_RefreshResult.temporaryFailure);
        return _RefreshResult.temporaryFailure;
      }
      final newRefresh =
          (data['refreshToken'] ?? data['refresh_token'])?.toString().trim() ??
              refreshToken;
      await TokenService.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      completer.complete(_RefreshResult.success);
      return _RefreshResult.success;
    } catch (_) {
      completer.complete(_RefreshResult.temporaryFailure);
      return _RefreshResult.temporaryFailure;
    } finally {
      _refreshInFlight = null;
    }
  }
}

enum _RefreshResult { success, invalidCredentials, temporaryFailure }
