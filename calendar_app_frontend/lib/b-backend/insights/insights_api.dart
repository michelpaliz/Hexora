import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/insights/json_transport.dart';
import 'package:hexora/b-backend/insights/sse_transport_io.dart'
    if (dart.library.html) 'package:hexora/b-backend/insights/sse_transport_web.dart';
import 'package:http/http.dart' as http;

class InsightsChatReply {
  final String text;
  final Map<String, dynamic> raw;

  const InsightsChatReply({
    required this.text,
    required this.raw,
  });
}

class InsightsExcelExport {
  const InsightsExcelExport({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.downloadJobId,
    this.downloadJobUrl,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
  final String? downloadJobId;
  final String? downloadJobUrl;
}

class InsightsExcelExportAction {
  const InsightsExcelExportAction({
    required this.type,
    required this.endpoint,
    required this.method,
    required this.body,
    this.filename,
  });

  final String type;
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final String? filename;

  static InsightsExcelExportAction? fromDynamic(dynamic input) {
    if (input is! Map) return null;
    final map = input.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    final type = map['type']?.toString().trim() ?? '';
    final endpoint = map['endpoint']?.toString().trim() ?? '';
    if (endpoint.isEmpty) return null;
    if (type.isNotEmpty && type != 'export_excel') return null;
    final rawMethod = map['method']?.toString().trim();
    final method = (rawMethod == null || rawMethod.isEmpty)
        ? 'POST'
        : rawMethod.toUpperCase();
    final rawBody = map['body'];
    final body = rawBody is Map
        ? rawBody.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    final filename = map['filename']?.toString().trim();
    return InsightsExcelExportAction(
      type: type.isEmpty ? 'export_excel' : type,
      endpoint: endpoint,
      method: method,
      body: body,
      filename: (filename == null || filename.isEmpty) ? null : filename,
    );
  }
}

enum InsightsChatEndpoint {
  chat('/chat'),
  chatAuto('/chat/auto'),
  chatStream('/chat/stream'),
  chatAutoStream('/chat/auto/stream');

  const InsightsChatEndpoint(this.path);
  final String path;
}

class InsightsTimeoutInfo {
  final String? status;
  final String? code;
  final int? timeoutMs;
  final bool canRetry;
  final String message;
  final String fallbackMessage;
  final Map<String, dynamic> raw;

  const InsightsTimeoutInfo({
    required this.status,
    required this.code,
    required this.timeoutMs,
    required this.canRetry,
    required this.message,
    required this.fallbackMessage,
    required this.raw,
  });

  String get displayMessage {
    final fallback = fallbackMessage.trim();
    if (fallback.isNotEmpty) return fallback;
    final msg = message.trim();
    if (msg.isNotEmpty) return msg;
    return 'Insights request timed out.';
  }
}

class InsightsChatResult {
  final String text;
  final Map<String, dynamic> raw;
  final InsightsTimeoutInfo? timeout;

  const InsightsChatResult({
    required this.text,
    required this.raw,
    this.timeout,
  });

  bool get timedOut => timeout != null;
}

class InsightsChatStreamEvent {
  final String delta;
  final InsightsTimeoutInfo? timeout;
  final Map<String, dynamic>? raw;

  const InsightsChatStreamEvent({
    required this.delta,
    this.timeout,
    this.raw,
  });

  bool get hasTimeout => timeout != null;
}

class InsightsApiException implements Exception {
  final int statusCode;
  final String message;
  final String? code;
  final Map<String, dynamic>? raw;

  const InsightsApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.raw,
  });

  @override
  String toString() => message;
}

class InsightsApi {
  InsightsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _base => ApiConstants.baseUrl.endsWith('/api')
      ? '${ApiConstants.baseUrl}/insights'
      : '${ApiConstants.baseUrl}/api/insights';

  Uri _u(String path) => Uri.parse('$_base$path');

  Uri get _healthUri => _resolveActionUri('/api/health');

  Future<Map<String, String>> _plainJsonHeaders() async => <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  Future<Map<String, String>> _plainAcceptHeaders(String accept) async =>
      <String, String>{
        'Accept': accept,
      };

  Future<Map<String, String>> _authJsonHeaders() {
    return AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: true,
      extra: const {'Accept': 'application/json'},
    );
  }

  Future<Map<String, String>> _authHeaders() {
    return AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
      extra: const {'Accept': 'application/json'},
    );
  }

  String _redactHeaders(Map<String, String> headers) {
    final safe = <String, String>{};
    headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization') {
        safe[key] = value.startsWith('Bearer ')
            ? 'Bearer ***${value.length > 10 ? value.substring(value.length - 6) : ''}'
            : 'present';
      } else {
        safe[key] = value;
      }
    });
    return safe.toString();
  }

  Future<void> _logRequest({
    required String tag,
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    final token = await TokenService.loadToken();
    final tokenPresent = token != null && token.trim().isNotEmpty;
    final isCrossOrigin = (uri.hasScheme &&
            Uri.base.hasScheme &&
            uri.scheme != Uri.base.scheme) ||
        (uri.hasScheme &&
            Uri.base.hasScheme &&
            uri.authority.isNotEmpty &&
            Uri.base.authority.isNotEmpty &&
            uri.authority != Uri.base.authority);
    debugPrint(
      '[InsightsApi][$tag] $method $uri '
      'baseUrl=${ApiConstants.baseUrl} '
      'origin=${Uri.base.origin} '
      'crossOrigin=$isCrossOrigin '
      'tokenPresent=$tokenPresent',
    );
    debugPrint('[InsightsApi][$tag] headers=${_redactHeaders(headers)}');
    if (body != null) {
      debugPrint('[InsightsApi][$tag] body=$body');
    }
  }

  void _logResponse({
    required String tag,
    required http.Response response,
  }) {
    debugPrint(
      '[InsightsApi][$tag] status=${response.statusCode} '
      'content-type=${response.headers['content-type']}',
    );
  }

  Future<void> _logFailure({
    required String tag,
    required Uri uri,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    debugPrint('[InsightsApi][$tag] failure uri=$uri');
    debugPrint('[InsightsApi][$tag] exceptionType=${error.runtimeType}');
    debugPrint('[InsightsApi][$tag] exception=$error');
    if (stackTrace != null) {
      debugPrint('[InsightsApi][$tag] stack=$stackTrace');
    }
    try {
      final healthHeaders = await _plainAcceptHeaders('application/json');
      final health = await AuthenticatedHttpClient.get(
        _healthUri,
        headers: healthHeaders,
        client: _client,
      );
      debugPrint(
        '[InsightsApi][$tag] healthProbe url=$_healthUri '
        'status=${health.statusCode} body=${utf8.decode(health.bodyBytes, allowMalformed: true)}',
      );
    } catch (probeError, probeStack) {
      debugPrint('[InsightsApi][$tag] healthProbeFailure=$probeError');
      debugPrint('[InsightsApi][$tag] healthProbeStack=$probeStack');
    }
  }

  bool _isBrowserFetchFailure(Object error) {
    if (error is! http.ClientException) return false;
    final message = error.message.toLowerCase();
    return message.contains('failed to fetch') ||
        message.contains('xhr request failed');
  }

  InsightsApiException _networkFailureException(Uri uri) {
    final isCrossOrigin = uri.hasScheme &&
        Uri.base.hasScheme &&
        uri.authority.isNotEmpty &&
        Uri.base.authority.isNotEmpty &&
        uri.authority != Uri.base.authority;
    final message = isCrossOrigin
        ? 'The browser blocked the Insights request before it reached the backend. '
            'This usually means a CORS or OPTIONS/preflight problem for /api/insights/*.'
        : 'The Insights request failed before a response was received.';
    return InsightsApiException(
      statusCode: 0,
      message: message,
      code: 'NETWORK_BLOCKED',
      raw: <String, dynamic>{
        'uri': uri.toString(),
        'crossOrigin': isCrossOrigin,
      },
    );
  }

  dynamic _tryDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  Map<String, dynamic> _toMap(dynamic input) {
    if (input is Map<String, dynamic>) return input;
    if (input is Map) {
      return input.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }

  String _resolveErrorMessage(http.Response response, dynamic body) {
    var message = response.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    return message;
  }

  String _downloadFileNameFromHeaders(
    Map<String, String> headers, {
    String fallback = 'insights-export.xlsx',
  }) {
    final raw =
        headers['content-disposition'] ?? headers['Content-Disposition'];
    if (raw != null && raw.trim().isNotEmpty) {
      final utf8Match =
          RegExp(r"filename\\*=UTF-8''([^;]+)", caseSensitive: false)
              .firstMatch(raw);
      if (utf8Match != null) {
        final decoded = Uri.decodeComponent(utf8Match.group(1)!);
        if (decoded.trim().isNotEmpty) return decoded.trim();
      }
      final match = RegExp(r'filename="?([^";]+)"?', caseSensitive: false)
          .firstMatch(raw);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        if (name.isNotEmpty) return name;
      }
    }
    return fallback;
  }

  Uri _resolveActionUri(String endpoint) {
    final trimmed = endpoint.trim();
    if (trimmed.isEmpty) {
      return _u('/chat/export/excel');
    }
    final absolute = Uri.tryParse(trimmed);
    if (absolute != null && absolute.hasScheme) {
      return absolute;
    }
    final baseOrigin = ApiConstants.baseUrl.startsWith('http://') ||
            ApiConstants.baseUrl.startsWith('https://')
        ? Uri.parse(ApiConstants.baseUrl).removeFragment().replace(
              path: '',
              query: null,
            )
        : Uri.base;
    if (trimmed.startsWith('/')) {
      return baseOrigin.resolve(trimmed);
    }
    if (trimmed.startsWith('api/')) {
      return baseOrigin.resolve('/$trimmed');
    }
    if (trimmed.startsWith('insights/')) {
      return baseOrigin.resolve('/api/$trimmed');
    }
    return _u(trimmed.startsWith('/') ? trimmed : '/$trimmed');
  }

  InsightsExcelExport _decodeExcelExport(http.Response response) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok) {
      final decoded = _tryDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      final asMap = decoded is Map ? _toMap(decoded) : null;
      throw InsightsApiException(
        statusCode: response.statusCode,
        message: _resolveErrorMessage(response, decoded),
        code: asMap?['code']?.toString(),
        raw: asMap,
      );
    }
    return InsightsExcelExport(
      bytes: response.bodyBytes,
      fileName: _downloadFileNameFromHeaders(response.headers),
      mimeType: response.headers['content-type'] ??
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      downloadJobId: response.headers['x-download-job-id'] ??
          response.headers['X-Download-Job-Id'],
      downloadJobUrl: response.headers['x-download-job-url'] ??
          response.headers['X-Download-Job-Url'],
    );
  }

  InsightsTimeoutInfo? _parseTimeout(dynamic body) {
    final map = _toMap(body);
    if (map.isEmpty) return null;

    final timeoutMap = map['timeout'] is Map ? _toMap(map['timeout']) : map;
    final code = timeoutMap['code']?.toString();
    final status = timeoutMap['status']?.toString();
    final isTimeoutCode = code == 'INSIGHTS_TIMEOUT';
    final isTimeoutStatus = status?.toLowerCase() == 'timeout';
    if (!isTimeoutCode && !isTimeoutStatus) return null;

    int? timeoutMs;
    final timeoutRaw = timeoutMap['timeoutMs'];
    if (timeoutRaw is num) {
      timeoutMs = timeoutRaw.toInt();
    } else if (timeoutRaw is String) {
      timeoutMs = int.tryParse(timeoutRaw);
    }

    final canRetryRaw = timeoutMap['canRetry'];
    final canRetry = canRetryRaw == true || canRetryRaw?.toString() == 'true';
    final message = timeoutMap['message']?.toString() ?? '';
    final fallbackMessage = timeoutMap['fallbackMessage']?.toString() ?? '';

    return InsightsTimeoutInfo(
      status: status,
      code: code,
      timeoutMs: timeoutMs,
      canRetry: canRetry,
      message: message,
      fallbackMessage: fallbackMessage,
      raw: timeoutMap,
    );
  }

  T _decode<T>(http.Response r, T Function(dynamic json) map) {
    final body = _tryDecode(r.body);
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    if (ok) return map(body);

    final timeout = (r.statusCode == 504) ? _parseTimeout(body) : null;
    if (timeout != null) {
      throw InsightsApiException(
        statusCode: r.statusCode,
        message: timeout.displayMessage,
        code: timeout.code,
        raw: _toMap(body),
      );
    }

    var message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    final mapBody = body is Map ? _toMap(body) : null;
    throw InsightsApiException(
      statusCode: r.statusCode,
      message: message,
      code: mapBody?['code']?.toString(),
      raw: mapBody,
    );
  }

  String _extractText(dynamic body) {
    if (body == null) return '';
    if (body is String) return body.trim();
    if (body is! Map) return '';
    final asMap = Map<String, dynamic>.from(body);

    final directCandidates = <dynamic>[
      asMap['delta'],
      asMap['chunk'],
      asMap['partial'],
      asMap['finalText'],
      asMap['final_text'],
      asMap['completion'],
      asMap['response'],
      asMap['reply'],
      asMap['message'],
      asMap['content'],
      asMap['text'],
      asMap['output'],
      asMap['answer'],
    ];
    for (final value in directCandidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    final nested = asMap['data'];
    if (nested is Map) {
      final text = _extractText(nested);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  Future<bool> health() async {
    final uri = _u('/health');
    final headers = await _authHeaders();
    await _logRequest(
      tag: 'health',
      method: 'GET',
      uri: uri,
      headers: headers,
    );
    final r = await _client.get(uri, headers: headers);
    _logResponse(tag: 'health', response: r);
    return _decode<bool>(r, (json) {
      if (json is Map && json['ok'] is bool) return json['ok'] as bool;
      return true;
    });
  }

  Map<String, dynamic> _buildChatPayload({
    required String message,
    String? groupId,
    int days = 90,
    double temperature = 0.2,
    int maxTokens = 800,
    int? timeoutMs,
    Map<String, dynamic>? extra,
    required InsightsChatEndpoint endpoint,
  }) {
    final payload = <String, dynamic>{
      'message': message,
      'temperature': temperature,
      'max_tokens': maxTokens,
      if (timeoutMs != null) 'timeoutMs': timeoutMs,
    };

    final usesAuto = endpoint == InsightsChatEndpoint.chatAuto ||
        endpoint == InsightsChatEndpoint.chatAutoStream;
    if (usesAuto) {
      final safeDays = days.clamp(30, 180);
      payload['days'] = safeDays;
      final safeGroupId = groupId?.trim() ?? '';
      if (safeGroupId.isNotEmpty) {
        payload['groupId'] = safeGroupId;
      }
    }

    if (extra != null && extra.isNotEmpty) {
      payload.addAll(extra);
    }
    return payload;
  }

  Future<InsightsChatResult> chat({
    required InsightsChatEndpoint endpoint,
    required String message,
    String? groupId,
    int days = 90,
    double temperature = 0.2,
    int maxTokens = 800,
    int? timeoutMs,
    Map<String, dynamic>? extra,
  }) async {
    final payload = _buildChatPayload(
      message: message,
      groupId: groupId,
      days: days,
      temperature: temperature,
      maxTokens: maxTokens,
      timeoutMs: timeoutMs,
      extra: extra,
      endpoint: endpoint,
    );
    final uri = _u(endpoint.path);
    final headers = await _plainJsonHeaders();
    final body = jsonEncode(payload);
    await _logRequest(
      tag: 'chat:${endpoint.name}',
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );
    late final http.Response r;
    try {
      final authorizedHeaders = await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: true,
        extra: const {'Accept': 'application/json'},
      );
      r = await postJsonTransport(
        uri: uri,
        headers: authorizedHeaders,
        body: body,
        client: _client,
      );
    } catch (error, stackTrace) {
      await _logFailure(
        tag: 'chat:${endpoint.name}',
        uri: uri,
        error: error,
        stackTrace: stackTrace,
      );
      if (_isBrowserFetchFailure(error)) {
        throw _networkFailureException(uri);
      }
      rethrow;
    }
    _logResponse(tag: 'chat:${endpoint.name}', response: r);

    final decodedBody = _tryDecode(r.body);
    final timeout = (r.statusCode == 504) ? _parseTimeout(decodedBody) : null;
    if (timeout != null) {
      return InsightsChatResult(
        text: timeout.displayMessage,
        raw: _toMap(decodedBody),
        timeout: timeout,
      );
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      _decode<Never>(r, (_) => throw StateError('unreachable'));
    }

    final raw = _toMap(decodedBody);
    return InsightsChatResult(
      text: _extractText(raw),
      raw: raw,
    );
  }

  Future<InsightsChatReply> chatAuto({
    required String message,
    required String groupId,
    int days = 90,
    double temperature = 0.2,
    int maxTokens = 800,
  }) async {
    final result = await chat(
      endpoint: InsightsChatEndpoint.chatAuto,
      message: message,
      groupId: groupId,
      days: days,
      temperature: temperature,
      maxTokens: maxTokens,
    );
    return InsightsChatReply(text: result.text, raw: result.raw);
  }

  Future<Map<String, dynamic>> chatRaw(Map<String, dynamic> payload) async {
    final result = await chat(
      endpoint: InsightsChatEndpoint.chat,
      message: payload['message']?.toString() ?? '',
      temperature: (payload['temperature'] as num?)?.toDouble() ?? 0.2,
      maxTokens: (payload['max_tokens'] as num?)?.toInt() ?? 800,
      timeoutMs: (payload['timeoutMs'] as num?)?.toInt(),
      extra: payload,
    );
    return result.raw;
  }

  Future<InsightsExcelExport> exportChatExcel({
    required String groupId,
    required String message,
  }) async {
    return downloadInsightsExcelFromAction(
      InsightsExcelExportAction(
        type: 'export_excel',
        endpoint: '/api/insights/chat/export/excel',
        method: 'POST',
        body: <String, dynamic>{
          'groupId': groupId.trim(),
          'message': message.trim(),
        },
        filename: null,
      ),
    );
  }

  Future<Map<String, dynamic>> previewChatEvent({
    required String groupId,
    required String message,
  }) async {
    final uri = _resolveActionUri('/api/insights/chat/events/preview');
    final headers = await _authJsonHeaders();
    final body = jsonEncode(<String, dynamic>{
      'groupId': groupId.trim(),
      'message': message.trim(),
    });
    await _logRequest(
      tag: 'events:preview',
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );
    late final http.Response response;
    try {
      response = await AuthenticatedHttpClient.post(
        uri,
        headers: headers,
        body: body,
        client: _client,
      );
    } catch (error, stackTrace) {
      await _logFailure(
        tag: 'events:preview',
        uri: uri,
        error: error,
        stackTrace: stackTrace,
      );
      if (_isBrowserFetchFailure(error)) {
        throw _networkFailureException(uri);
      }
      rethrow;
    }
    _logResponse(tag: 'events:preview', response: response);
    return _decode<Map<String, dynamic>>(response, _toMap);
  }

  Future<Map<String, dynamic>> confirmChatEvent({
    required String groupId,
    required Map<String, dynamic> eventPayload,
    bool confirm = true,
  }) async {
    final uri = _resolveActionUri('/api/insights/chat/events/confirm');
    final headers = await _authJsonHeaders();
    final body = jsonEncode(<String, dynamic>{
      'groupId': groupId.trim(),
      'confirm': confirm,
      'eventPayload': eventPayload,
    });
    await _logRequest(
      tag: 'events:confirm',
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );
    late final http.Response response;
    try {
      response = await AuthenticatedHttpClient.post(
        uri,
        headers: headers,
        body: body,
        client: _client,
      );
    } catch (error, stackTrace) {
      await _logFailure(
        tag: 'events:confirm',
        uri: uri,
        error: error,
        stackTrace: stackTrace,
      );
      if (_isBrowserFetchFailure(error)) {
        throw _networkFailureException(uri);
      }
      rethrow;
    }
    _logResponse(tag: 'events:confirm', response: response);
    return _decode<Map<String, dynamic>>(response, _toMap);
  }

  Future<InsightsExcelExport> downloadInsightsExcelFromAction(
    InsightsExcelExportAction action,
  ) async {
    if (action.type != 'export_excel') {
      throw const InsightsApiException(
        statusCode: 400,
        message: 'Invalid export action type.',
      );
    }
    final uri = _resolveActionUri(action.endpoint);
    final acceptHeaders = await _plainAcceptHeaders(
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/octet-stream',
    );
    late final http.Response response;
    switch (action.method.toUpperCase()) {
      case 'POST':
        final body = jsonEncode(action.body);
        await _logRequest(
          tag: 'export:post',
          method: 'POST',
          uri: uri,
          headers: {
            ...acceptHeaders,
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: body,
        );
        try {
          response = await AuthenticatedHttpClient.post(
            uri,
            headers: {
              ...acceptHeaders,
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: body,
            client: _client,
          );
        } catch (error, stackTrace) {
          await _logFailure(
            tag: 'export:post',
            uri: uri,
            error: error,
            stackTrace: stackTrace,
          );
          if (_isBrowserFetchFailure(error)) {
            throw _networkFailureException(uri);
          }
          rethrow;
        }
        break;
      case 'GET':
        final query = action.body.map(
          (key, value) => MapEntry(key, value?.toString() ?? ''),
        );
        final getUri = uri.replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            ...query,
          },
        );
        await _logRequest(
          tag: 'export:get',
          method: 'GET',
          uri: getUri,
          headers: acceptHeaders,
        );
        try {
          response = await AuthenticatedHttpClient.get(
            getUri,
            headers: acceptHeaders,
            client: _client,
          );
        } catch (error, stackTrace) {
          await _logFailure(
            tag: 'export:get',
            uri: getUri,
            error: error,
            stackTrace: stackTrace,
          );
          if (_isBrowserFetchFailure(error)) {
            throw _networkFailureException(getUri);
          }
          rethrow;
        }
        break;
      default:
        throw InsightsApiException(
          statusCode: 400,
          message: 'Unsupported export method: ${action.method}',
        );
    }
    _logResponse(
        tag: 'export:${action.method.toLowerCase()}', response: response);
    final decoded = _decodeExcelExport(response);
    final fallbackName = action.filename?.trim();
    if (fallbackName != null && fallbackName.isNotEmpty) {
      return InsightsExcelExport(
        bytes: decoded.bytes,
        fileName: fallbackName,
        mimeType: decoded.mimeType,
      );
    }
    return decoded;
  }

  Future<Map<String, dynamic>> executeJsonAction(
    Map<String, dynamic> action,
  ) async {
    final endpoint = action['endpoint']?.toString().trim() ?? '';
    if (endpoint.isEmpty) {
      throw const InsightsApiException(
        statusCode: 400,
        message: 'Missing action endpoint.',
      );
    }
    final method = (action['method']?.toString().trim().isNotEmpty == true)
        ? action['method'].toString().trim().toUpperCase()
        : 'GET';
    final uri = _resolveActionUri(endpoint);

    Map<String, dynamic> firstMap(List<dynamic> values) {
      for (final value in values) {
        if (value is Map) {
          return value.map((key, value) => MapEntry(key.toString(), value));
        }
      }
      return <String, dynamic>{};
    }

    Map<String, String> queryMapFrom(Map<String, dynamic> input) {
      final out = <String, String>{};
      input.forEach((key, value) {
        if (value == null) return;
        if (value is List) {
          final joined = value
              .map((item) => item?.toString().trim() ?? '')
              .where((item) => item.isNotEmpty)
              .join(',');
          if (joined.isNotEmpty) out[key] = joined;
          return;
        }
        final text = value.toString().trim();
        if (text.isNotEmpty) out[key] = text;
      });
      return out;
    }

    final bodyMap = firstMap([
      action['body'],
      action['payload'],
      action['data'],
    ]);
    final queryMap = firstMap([
      action['query'],
      action['queryParams'],
      action['query_parameters'],
      action['params'],
    ]);
    final headers = await _authJsonHeaders();
    late final http.Response response;

    switch (method) {
      case 'GET':
        final getUri = uri.replace(
          queryParameters: <String, String>{
            ...uri.queryParameters,
            ...queryMapFrom(queryMap),
            ...queryMapFrom(bodyMap),
          },
        );
        await _logRequest(
          tag: 'json-action:get',
          method: 'GET',
          uri: getUri,
          headers: headers,
        );
        try {
          response = await AuthenticatedHttpClient.get(
            getUri,
            headers: headers,
            client: _client,
          );
        } catch (error, stackTrace) {
          await _logFailure(
            tag: 'json-action:get',
            uri: getUri,
            error: error,
            stackTrace: stackTrace,
          );
          if (_isBrowserFetchFailure(error)) {
            throw _networkFailureException(getUri);
          }
          rethrow;
        }
        break;
      case 'POST':
        final body = jsonEncode(bodyMap);
        await _logRequest(
          tag: 'json-action:post',
          method: 'POST',
          uri: uri,
          headers: headers,
          body: body,
        );
        try {
          response = await AuthenticatedHttpClient.post(
            uri,
            headers: headers,
            body: body,
            client: _client,
          );
        } catch (error, stackTrace) {
          await _logFailure(
            tag: 'json-action:post',
            uri: uri,
            error: error,
            stackTrace: stackTrace,
          );
          if (_isBrowserFetchFailure(error)) {
            throw _networkFailureException(uri);
          }
          rethrow;
        }
        break;
      default:
        throw InsightsApiException(
          statusCode: 400,
          message: 'Unsupported action method: $method',
        );
    }

    _logResponse(
        tag: 'json-action:${method.toLowerCase()}', response: response);
    return _decode<Map<String, dynamic>>(response, _toMap);
  }

  Future<Map<String, dynamic>> analyze(Map<String, dynamic> payload) async {
    final uri = _u('/analyze');
    final headers = await _plainJsonHeaders();
    final body = jsonEncode(payload);
    await _logRequest(
      tag: 'analyze',
      method: 'POST',
      uri: uri,
      headers: headers,
      body: body,
    );
    late final http.Response r;
    try {
      final authorizedHeaders = await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: true,
        extra: const {'Accept': 'application/json'},
      );
      r = await postJsonTransport(
        uri: uri,
        headers: authorizedHeaders,
        body: body,
        client: _client,
      );
    } catch (error, stackTrace) {
      await _logFailure(
        tag: 'analyze',
        uri: uri,
        error: error,
        stackTrace: stackTrace,
      );
      if (_isBrowserFetchFailure(error)) {
        throw _networkFailureException(uri);
      }
      rethrow;
    }
    _logResponse(tag: 'analyze', response: r);
    return _decode<Map<String, dynamic>>(r, (json) {
      if (json is Map<String, dynamic>) return json;
      return <String, dynamic>{'raw': json};
    });
  }

  Stream<String> chatStream(Map<String, dynamic> payload) async* {
    final message = payload['message']?.toString() ?? '';
    final groupId = payload['groupId']?.toString();
    final days = (payload['days'] as num?)?.toInt() ?? 90;
    final temperature = (payload['temperature'] as num?)?.toDouble() ?? 0.2;
    final maxTokens = (payload['max_tokens'] as num?)?.toInt() ?? 800;
    final timeoutMs = (payload['timeoutMs'] as num?)?.toInt();
    final endpoint =
        payload['_endpoint'] == InsightsChatEndpoint.chatStream.name
            ? InsightsChatEndpoint.chatStream
            : InsightsChatEndpoint.chatAutoStream;

    await for (final event in streamChat(
      endpoint: endpoint,
      message: message,
      groupId: groupId,
      days: days,
      temperature: temperature,
      maxTokens: maxTokens,
      timeoutMs: timeoutMs,
      extra: payload,
    )) {
      if (event.delta.trim().isNotEmpty) {
        yield event.delta;
      }
    }
  }

  Stream<InsightsChatStreamEvent> streamChat({
    required InsightsChatEndpoint endpoint,
    required String message,
    String? groupId,
    int days = 90,
    double temperature = 0.2,
    int maxTokens = 800,
    int? timeoutMs,
    Map<String, dynamic>? extra,
  }) async* {
    if (endpoint != InsightsChatEndpoint.chatStream &&
        endpoint != InsightsChatEndpoint.chatAutoStream) {
      throw const InsightsApiException(
        statusCode: 400,
        message: 'Invalid streaming endpoint.',
      );
    }

    final payload = _buildChatPayload(
      message: message,
      groupId: groupId,
      days: days,
      temperature: temperature,
      maxTokens: maxTokens,
      timeoutMs: timeoutMs,
      extra: extra,
      endpoint: endpoint,
    );

    await for (final line in postSseLines(
      uri: _u(endpoint.path),
      headers: await _authJsonHeaders(),
      body: jsonEncode(payload),
      client: _client,
    )) {
      if (line.trim().isEmpty) continue;
      dynamic payloadLine;
      try {
        payloadLine = jsonDecode(line);
      } catch (_) {
        payloadLine = line;
      }

      final timeout = _parseTimeout(payloadLine);
      final rawMap =
          payloadLine is Map ? _toMap(payloadLine) : <String, dynamic>{};
      var delta = _extractText(payloadLine);
      if (delta.isEmpty && payloadLine is String) {
        delta = payloadLine.trim();
      }
      if (timeout != null && delta.isEmpty) {
        delta = timeout.displayMessage;
      }

      if (delta.isEmpty && timeout == null) continue;
      yield InsightsChatStreamEvent(
        delta: delta,
        timeout: timeout,
        raw: rawMap.isEmpty ? null : rawMap,
      );
    }
  }
}
