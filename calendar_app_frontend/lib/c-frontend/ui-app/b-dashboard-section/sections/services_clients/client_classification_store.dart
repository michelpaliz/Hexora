import 'dart:convert';

import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ClientClassificationOptions {
  final List<String> entityTypes;
  final List<String> propertyKinds;

  const ClientClassificationOptions({
    required this.entityTypes,
    required this.propertyKinds,
  });
}

class ClientClassificationStore {
  static String _base(String groupId) =>
      '${ApiConstants.baseUrl}/groups/$groupId/client-classification-options';

  static Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  static String? normalize(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty) return null;
    return v.length > 50 ? v.substring(0, 50) : v;
  }

  static ClientClassificationOptions _fromJson(dynamic body) {
    if (body is! Map) {
      throw Exception('Unexpected classification options payload');
    }
    final entityTypes = (body['entityTypes'] is List)
        ? (body['entityTypes'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final propertyKinds = (body['propertyKinds'] is List)
        ? (body['propertyKinds'] as List).map((e) => e.toString()).toList()
        : <String>[];
    return ClientClassificationOptions(
      entityTypes: entityTypes,
      propertyKinds: propertyKinds,
    );
  }

  static Exception _decodeError(http.Response r) {
    if (kDebugMode) {
      debugPrint(
        '[ClientClassificationStore] ${r.request?.method} ${r.request?.url} '
        '-> ${r.statusCode} body=${r.body}',
      );
    }
    try {
      final b = jsonDecode(r.body);
      if (b is Map && b['message'] != null) return Exception(b['message']);
      return Exception(
        '${r.reasonPhrase ?? 'Request failed'} (status ${r.statusCode})',
      );
    } catch (_) {
      final excerpt = r.body.trim();
      final clipped = excerpt.length > 240 ? '${excerpt.substring(0, 240)}…' : excerpt;
      return Exception(
        '${r.reasonPhrase ?? 'Request failed'} (status ${r.statusCode})'
        '${clipped.isEmpty ? '' : ': $clipped'}',
      );
    }
  }

  static Future<ClientClassificationOptions> getOptions(String groupId) async {
    final r =
        await http.get(Uri.parse(_base(groupId)), headers: await _headers());
    if (r.statusCode == 404) {
      // Avoid hard-crashing the UI if the endpoint is missing on the backend.
      if (kDebugMode) {
        debugPrint(
          '[ClientClassificationStore] GET ${r.request?.url} -> 404; returning empty options',
        );
      }
      return const ClientClassificationOptions(entityTypes: [], propertyKinds: []);
    }
    if (r.statusCode < 200 || r.statusCode >= 300) throw _decodeError(r);
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    return _fromJson(body);
  }

  static Future<ClientClassificationOptions> replaceOptions({
    required String groupId,
    required List<String> entityTypes,
    required List<String> propertyKinds,
  }) async {
    final payload = {
      'entityTypes':
          entityTypes.map((e) => normalize(e)).whereType<String>().toList(),
      'propertyKinds':
          propertyKinds.map((e) => normalize(e)).whereType<String>().toList(),
    };
    final r = await http.put(
      Uri.parse(_base(groupId)),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _decodeError(r);
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    return _fromJson(body);
  }

  static Future<ClientClassificationOptions> merge({
    required String groupId,
    String? entityType,
    String? propertyKind,
  }) async {
    final payload = <String, dynamic>{};
    final e = normalize(entityType);
    final p = normalize(propertyKind);
    if (e != null) payload['entityType'] = e;
    if (p != null) payload['propertyKind'] = p;

    final r = await http.post(
      Uri.parse(_base(groupId)),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _decodeError(r);
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    return _fromJson(body);
  }

  static Future<ClientClassificationOptions> remove({
    required String groupId,
    String? entityType,
    String? propertyKind,
  }) async {
    final payload = <String, dynamic>{};
    final e = normalize(entityType);
    final p = normalize(propertyKind);
    if (e != null) payload['entityType'] = e;
    if (p != null) payload['propertyKind'] = p;

    final r = await http.delete(
      Uri.parse(_base(groupId)),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _decodeError(r);
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    return _fromJson(body);
  }

  static Future<ClientClassificationOptions> rebuild(String groupId) async {
    final r = await http.post(
      Uri.parse('${_base(groupId)}/rebuild'),
      headers: await _headers(),
    );
    if (r.statusCode < 200 || r.statusCode >= 300) throw _decodeError(r);
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    return _fromJson(body);
  }
}
