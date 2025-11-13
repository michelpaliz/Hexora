import 'dart:convert';

import 'package:hexora/a-models/group_model/client/client.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class ClientsApi {
  final String _base = '${ApiConstants.baseUrl}/clients';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  Uri _u([String path = '', Map<String, String?> q = const {}]) {
    final filtered = Map.fromEntries(
      q.entries.where((e) => e.value != null && e.value!.isNotEmpty),
    );
    return Uri.parse('$_base$path')
        .replace(queryParameters: filtered.isEmpty ? null : filtered);
  }

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = r.body.isEmpty ? null : jsonDecode(r.body);
      return map(body);
    }
    String msg;
    try {
      final j = jsonDecode(r.body);
      msg = j is Map && j['message'] is String
          ? j['message']
          : r.reasonPhrase ?? 'Request failed';
    } catch (_) {
      msg = r.reasonPhrase ?? 'Request failed';
    }
    throw Exception(msg);
  }

  // GET /clients?groupId=...&active=true|false
  Future<List<GroupClient>> list({String? groupId, bool? active}) async {
    final r = await http.get(
        _u('', {
          'groupId': groupId,
          if (active != null) 'active': active.toString(),
        }),
        headers: await _headers());

    return _decode<List<GroupClient>>(r, (j) {
      if (j is! List) throw Exception('Unexpected clients payload');
      return j.map<GroupClient>((e) => GroupClient.fromJson(e)).toList();
    });
  }

  // POST /clients
// POST /clients
  Future<GroupClient> create(GroupClient client) async {
    final body = <String, dynamic>{
      'groupId': client.groupId,
      'name': client.name.trim(),
      'isActive': client.isActive,
      'contact': {
        if ((client.phone ?? '').trim().isNotEmpty)
          'phone': client.phone!.trim(),
        if ((client.email ?? '').trim().isNotEmpty)
          'email': client.email!.trim(),
      },
      // if you use meta on FE:
      // if (client.meta != null) 'meta': client.meta,
    };

    final r = await http.post(
      _u(),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode<GroupClient>(r, (j) => GroupClient.fromJson(j));
  }

  // GET /clients/:id
  Future<GroupClient> getById(String id) async {
    final r = await http.get(_u('/$id'), headers: await _headers());
    return _decode<GroupClient>(r, (j) => GroupClient.fromJson(j));
  }

  // PATCH /clients/:id  (full update: send client.toJson())
  Future<GroupClient> update(GroupClient client) async {
    if (client.id.isEmpty) throw Exception('Client.id is required');
    final patch = <String, dynamic>{
      'name': client.name.trim(),
      'isActive': client.isActive,
      'contact': {
        'phone':
            (client.phone ?? '').trim().isEmpty ? null : client.phone!.trim(),
        'email':
            (client.email ?? '').trim().isEmpty ? null : client.email!.trim(),
      },
      // if (client.meta != null) 'meta': client.meta,
    };
    final r = await http.patch(
      _u('/${client.id}'),
      headers: await _headers(),
      body: jsonEncode(patch),
    );
    return _decode<GroupClient>(r, (j) => GroupClient.fromJson(j));
  }

  // PATCH /clients/:id  (partial fields)
  Future<GroupClient> updateFields(
      String id, Map<String, dynamic> fields) async {
    final r = await http.patch(
      _u('/$id'),
      headers: await _headers(),
      body: jsonEncode(fields),
    );
    return _decode<GroupClient>(r, (j) => GroupClient.fromJson(j));
  }

  // PATCH /clients/:id/active  { isActive: true|false }
  Future<GroupClient> setActive(String id, bool isActive) async {
    final r = await http.patch(
      _u('/$id/active'),
      headers: await _headers(),
      body: jsonEncode({'isActive': isActive}),
    );
    return _decode<GroupClient>(r, (j) => GroupClient.fromJson(j));
  }
}
