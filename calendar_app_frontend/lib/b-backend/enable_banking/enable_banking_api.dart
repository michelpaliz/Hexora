import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class EnableBankingApiException implements Exception {
  final int statusCode;
  final String message;
  final Uri url;
  final String method;
  final String? responseBody;
  final Map<String, String>? responseHeaders;

  EnableBankingApiException({
    required this.statusCode,
    required this.message,
    required this.url,
    required this.method,
    required this.responseBody,
    required this.responseHeaders,
  });

  @override
  String toString() {
    final body = (responseBody == null || responseBody!.trim().isEmpty)
        ? ''
        : '\nbody: ${responseBody!.trim()}';
    return 'EnableBanking API ($statusCode) $method $url: $message$body';
  }
}

class EnableBankingApi {
  final String _base = '${ApiConstants.baseUrl}/enablebanking';
  bool _loggedAuthSummary = false;
  String? _lastJwtSummary;

  Uri _u([String path = '', Map<String, String>? query]) =>
      Uri.parse('$_base$path').replace(queryParameters: query);

  static String _truncate(String s, {int max = 1200}) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…(truncated, len=${s.length})';
  }

  static String _padBase64Url(String input) {
    final pad = (4 - input.length % 4) % 4;
    return input + ('=' * pad);
  }

  static Map<String, dynamic>? _tryDecodeJwtClaims(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final payload = utf8.decode(base64Url.decode(_padBase64Url(parts[1])));
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic>? _tryDecodeJwtHeader(String token) {
    try {
      final parts = token.split('.');
      if (parts.isEmpty) return null;
      final header = utf8.decode(base64Url.decode(_padBase64Url(parts[0])));
      final decoded = jsonDecode(header);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  static String _jwtSummary(String token) {
    final partsCount = token.split('.').length;
    final claims = _tryDecodeJwtClaims(token);
    final header = _tryDecodeJwtHeader(token);
    if (claims == null) {
      final alg = header?['alg']?.toString() ?? '(unknown)';
      final kid = header?['kid']?.toString();
      final kidStr = kid == null ? '' : ' kid=$kid';
      return 'parts=$partsCount alg=$alg$kidStr (unparseable payload)';
    }
    final aud = claims['aud'];
    final iss = claims['iss'];
    final sub = claims['sub'];
    final exp = claims['exp'];
    final alg = header?['alg']?.toString();
    final kid = header?['kid']?.toString();

    String audStr;
    if (aud is List) {
      audStr = aud.map((e) => e.toString()).join(',');
    } else {
      audStr = aud?.toString() ?? '(none)';
    }

    String expStr = '(none)';
    if (exp is int) {
      expStr =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000).toIso8601String();
    } else if (exp is String) {
      expStr = exp;
    }

    final keys = claims.keys.toList()..sort();
    final keysStr = keys.join(',');

    return [
      'parts=$partsCount',
      if (alg != null) 'alg=$alg',
      if (kid != null) 'kid=$kid',
      'aud=$audStr',
      'iss=${iss ?? '(none)'}',
      'sub=${sub ?? '(none)'}',
      'exp=$expStr',
      'keys=[$keysStr]',
    ].join(' ');
  }

  Future<Map<String, String>> _headers() async {
    final token = await TokenService.loadToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated (missing access token)');
    }
    _lastJwtSummary = _jwtSummary(token);
    if (kDebugMode && !_loggedAuthSummary) {
      _loggedAuthSummary = true;
      debugPrint('[EnableBankingApi] baseUrl=${ApiConstants.baseUrl}');
      debugPrint('[EnableBankingApi] jwt: $_lastJwtSummary');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  T _decode<T>(
    http.Response r, {
    required Uri url,
    required String method,
    required T Function(dynamic) map,
  }) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    if (ok) {
      try {
        return map(body);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[EnableBankingApi] Response parse error: $method $url');
          debugPrint('[EnableBankingApi] Error: $e');
          debugPrint('[EnableBankingApi] Body: ${_truncate(r.body)}');
          debugPrintStack(stackTrace: st);
        }
        rethrow;
      }
    }

    String msg = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      msg = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      msg = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body.trim();
    }
    final ex = EnableBankingApiException(
      statusCode: r.statusCode,
      message: msg,
      url: url,
      method: method,
      responseBody: r.body.isEmpty ? null : r.body,
      responseHeaders: r.headers,
    );
    if (kDebugMode) {
      debugPrint(ex.toString());
      if (r.headers['www-authenticate'] != null) {
        debugPrint('www-authenticate: ${r.headers['www-authenticate']}');
      }
      if (r.statusCode == 401 || r.statusCode == 403) {
        if (_lastJwtSummary != null) {
          debugPrint('[EnableBankingApi] jwt: $_lastJwtSummary');
        }
      }
    }
    throw ex;
  }

  Future<List<Map<String, dynamic>>> listBanks(
      {required String country}) async {
    final uri = _u('/aspsps', {'country': country});
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        dynamic list = j;
        if (j is Map) {
          // Known backend shapes:
          // - [ ... ]
          // - { aspsps: [ ... ] }
          // - { banks: [ ... ] }
          // - { data/items/result: [ ... ] }
          // - { country: "ES", aspsps: { aspsps: [ ... ] } }
          final m = Map<String, dynamic>.from(j);

          final aspsps = m['aspsps'];
          if (aspsps is List) {
            list = aspsps;
          } else if (aspsps is Map && aspsps['aspsps'] is List) {
            list = aspsps['aspsps'];
          } else if (m['banks'] is List) {
            list = m['banks'];
          } else if (m['data'] is List) {
            list = m['data'];
          } else if (m['items'] is List) {
            list = m['items'];
          } else if (m['result'] is List) {
            list = m['result'];
          } else if (m['data'] is Map) {
            final dm = Map<String, dynamic>.from(m['data'] as Map);
            if (dm['aspsps'] is List) list = dm['aspsps'];
            if (dm['banks'] is List) list = dm['banks'];
          }
        }

        if (list is! List) {
          if (j is Map) {
            final keys = j.keys.map((k) => k.toString()).toList()..sort();
            throw Exception(
              'Unexpected banks payload (type=${j.runtimeType}, keys=$keys). Check response body in logs.',
            );
          }
          throw Exception(
            'Unexpected banks payload (type=${j.runtimeType}). Check response body in logs.',
          );
        }

        return list
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      },
    );
  }

  /// GET /enablebanking/connect -> { url, authorization_id, state }
  Future<Map<String, dynamic>> connect({
    required String country,
    String? aspspName,
  }) async {
    final query = <String, String>{'country': country};
    if (aspspName != null && aspspName.trim().isNotEmpty) {
      query['aspsp_name'] = aspspName.trim();
    }
    final uri = _u('/connect', query);
    final r = await http.get(uri, headers: await _headers());
    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is! Map) throw Exception('Unexpected connect payload');
        return Map<String, dynamic>.from(j);
      },
    );
  }

  /// GET /enablebanking/accounts -> accounts list (post-consent)
  Future<List<Map<String, dynamic>>> listAccounts() async {
    final uri = _u('/accounts');
    final r = await http.get(uri, headers: await _headers());
    return _decode<List<Map<String, dynamic>>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is! List) throw Exception('Unexpected accounts payload');
        return j
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      },
    );
  }

  /// GET /enablebanking/transactions?accountId=...&date_from=YYYY-MM-DD&date_to=YYYY-MM-DD
  ///
  /// The backend may return extra fields like:
  /// { cached: true, warning: "rate_limited", transactions: [...] }
  Future<Map<String, dynamic>> transactions({
    required String accountId,
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final uri = _u('/transactions', {
      'accountId': accountId,
      'date_from': ymd(dateFrom),
      'date_to': ymd(dateTo),
    });
    final r = await http.get(uri, headers: await _headers());

    return _decode<Map<String, dynamic>>(
      r,
      url: uri,
      method: 'GET',
      map: (j) {
        if (j is Map) return Map<String, dynamic>.from(j);
        if (j is List) {
          return {
            'transactions': j
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList(),
          };
        }
        throw Exception('Unexpected transactions payload');
      },
    );
  }
}
