import 'dart:async';
import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
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
      asMap['response'],
      asMap['reply'],
      asMap['message'],
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
    final r = await _client.get(_u('/health'), headers: await _authHeaders());
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
    final r = await _client.post(
      _u(endpoint.path),
      headers: await _authJsonHeaders(),
      body: jsonEncode(payload),
    );

    final body = _tryDecode(r.body);
    final timeout = (r.statusCode == 504) ? _parseTimeout(body) : null;
    if (timeout != null) {
      return InsightsChatResult(
        text: timeout.displayMessage,
        raw: _toMap(body),
        timeout: timeout,
      );
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      _decode<Never>(r, (_) => throw StateError('unreachable'));
    }

    final raw = _toMap(body);
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

  Future<Map<String, dynamic>> analyze(Map<String, dynamic> payload) async {
    final r = await _client.post(
      _u('/analyze'),
      headers: await _authJsonHeaders(),
      body: jsonEncode(payload),
    );
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
    final endpoint = payload['_endpoint'] == InsightsChatEndpoint.chatStream.name
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
