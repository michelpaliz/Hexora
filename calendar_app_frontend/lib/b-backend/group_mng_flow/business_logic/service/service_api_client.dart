import 'dart:convert';
import 'dart:io';

import 'package:hexora/a-models/group_model/service/service.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class PagedResult<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int skip;
  final bool hasMore;

  PagedResult({
    required this.items,
    required this.total,
    required this.limit,
    required this.skip,
    required this.hasMore,
  });

  factory PagedResult.fromJson(
    Map<String, dynamic> j,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsJson = (j['items'] as List?) ?? const [];
    return PagedResult<T>(
      items: itemsJson
          .map<T>((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      total: (j['total'] as num?)?.toInt() ?? itemsJson.length,
      limit: (j['limit'] as num?)?.toInt() ?? itemsJson.length,
      skip: (j['skip'] as num?)?.toInt() ?? 0,
      hasMore: j['hasMore'] == true,
    );
  }
}

class ServiceApi {
  final String _base = '${ApiConstants.baseUrl}/services';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  Uri _u([String path = '', Map<String, Object?> q = const {}]) {
    final filtered = <String, String>{};
    q.forEach((k, v) {
      if (v == null) return;
      final s = v is String ? v : v.toString();
      if (s.isNotEmpty) filtered[k] = s;
    });
    return Uri.parse('$_base$path')
        .replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    final hasBody = r.body.isNotEmpty;
    dynamic body;
    if (hasBody) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {/* leave as raw string */}
    }

    if (ok) {
      return map(body);
    }

    // Extract meaningful error message
    String msg;
    if (body is Map) {
      // backend sends { error: "..."} or sometimes { message: "..." }
      msg = (body['error'] ??
              body['message'] ??
              r.reasonPhrase ??
              'Request failed')
          .toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body;
    } else {
      msg = r.reasonPhrase ?? 'Request failed';
    }
    throw ApiException(r.statusCode, msg);
  }

  // GET /services?groupId=...&active=true|false[&q=...&limit=...&skip=...]
  // Convenience: returns only the items array
  Future<List<Service>> list({
    required String groupId,
    bool? active,
    String? q,
    int? limit,
    int? skip,
  }) async {
    final r = await http.get(
      _u('', {
        'groupId': groupId,
        if (active != null) 'active': active,
        if (q != null) 'q': q,
        if (limit != null) 'limit': limit,
        if (skip != null) 'skip': skip,
      }),
      headers: await _headers(),
    );

    return _decode<List<Service>>(r, (j) {
      // New backend shape is an object; keep backward-compat if server returns an array
      if (j is List) {
        return j
            .map<Service>((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (j is Map<String, dynamic>) {
        final items = (j['items'] as List?) ?? const [];
        return items
            .map<Service>((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw ApiException(500, 'Unexpected services payload');
    });
  }

  // Full pagination object
  Future<PagedResult<Service>> listPaged({
    required String groupId,
    bool? active,
    String? q,
    int? limit,
    int? skip,
  }) async {
    final r = await http.get(
      _u('', {
        'groupId': groupId,
        if (active != null) 'active': active,
        if (q != null) 'q': q,
        if (limit != null) 'limit': limit,
        if (skip != null) 'skip': skip,
      }),
      headers: await _headers(),
    );

    return _decode<PagedResult<Service>>(r, (j) {
      if (j is Map<String, dynamic>) {
        return PagedResult<Service>.fromJson(j, (m) => Service.fromJson(m));
      }
      if (j is List) {
        // Gracefully handle older server payloads
        final items = j
            .map<Service>((e) => Service.fromJson(e as Map<String, dynamic>))
            .toList();
        return PagedResult<Service>(
          items: items,
          total: items.length,
          limit: items.length,
          skip: 0,
          hasMore: false,
        );
      }
      throw ApiException(500, 'Unexpected services payload');
    });
  }

  // POST /services
  Future<Service> create(Service service) async {
    final r = await http.post(
      _u(),
      headers: await _headers(),
      body: jsonEncode(service.toJson()),
    );
    return _decode<Service>(
        r, (j) => Service.fromJson(j as Map<String, dynamic>));
  }

  // GET /services/:id
  Future<Service> getById(String id) async {
    final r = await http.get(_u('/$id'), headers: await _headers());
    return _decode<Service>(
        r, (j) => Service.fromJson(j as Map<String, dynamic>));
  }

  // PATCH /services/:id  (full update)
  Future<Service> update(Service service) async {
    if (service.id.isEmpty)
      throw ApiException(HttpStatus.badRequest, 'Service.id is required');
    final r = await http.patch(
      _u('/${service.id}'),
      headers: await _headers(),
      body: jsonEncode(service.toJson()),
    );
    return _decode<Service>(
        r, (j) => Service.fromJson(j as Map<String, dynamic>));
  }

  // PATCH /services/:id  (partial fields)
  Future<Service> updateFields(String id, Map<String, dynamic> fields) async {
    final r = await http.patch(
      _u('/$id'),
      headers: await _headers(),
      body: jsonEncode(fields),
    );
    return _decode<Service>(
        r, (j) => Service.fromJson(j as Map<String, dynamic>));
  }

  // PATCH /services/:id/active  { isActive: true|false }
  Future<Service> setActive(String id, bool isActive) async {
    final r = await http.patch(
      _u('/$id/active'),
      headers: await _headers(),
      body: jsonEncode({'isActive': isActive}),
    );
    return _decode<Service>(
        r, (j) => Service.fromJson(j as Map<String, dynamic>));
  }
}
