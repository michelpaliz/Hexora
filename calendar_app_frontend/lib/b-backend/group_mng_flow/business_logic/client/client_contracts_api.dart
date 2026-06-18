import 'dart:convert';
import 'dart:developer' as devtools show log;

import 'package:hexora/a-models/group_model/client/client_contract.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ClientContractsApi {
  final String _base = '${ApiConstants.baseUrl}/clients';

  Uri _u(String clientId, [String path = '']) =>
      Uri.parse('$_base/$clientId/contracts$path');

  Map<String, String> _headers() => const {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  T _decode<T>(http.Response r, T Function(dynamic body) map) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      final body = r.body.isEmpty ? null : jsonDecode(r.body);
      return map(body);
    }
    devtools.log(
      'ClientContractsApi error ${r.request?.method} ${r.request?.url} '
      'status=${r.statusCode} body=${r.body}',
      name: 'ClientContractsApi',
    );
    String message;
    try {
      final decoded = jsonDecode(r.body);
      message = decoded is Map && decoded['message'] is String
          ? decoded['message'] as String
          : r.reasonPhrase ?? 'Request failed';
    } catch (_) {
      message = r.reasonPhrase ?? 'Request failed';
    }
    throw Exception(message);
  }

  List<ClientContract> _mapContracts(dynamic body) {
    final list = body is List
        ? body
        : body is Map && body['contracts'] is List
            ? body['contracts'] as List
            : const <dynamic>[];
    return list
        .whereType<Map>()
        .map((item) => ClientContract.fromJson(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  ClientContract _mapContract(dynamic body) {
    final item = body is Map && body['contract'] is Map ? body['contract'] : body;
    if (item is Map) {
      return ClientContract.fromJson(item.cast<String, dynamic>());
    }
    throw Exception('Unexpected contract payload');
  }

  ClientContractFileRef _mapFile(dynamic body) {
    final item = body is Map && body['file'] is Map ? body['file'] : body;
    if (item is Map) {
      return ClientContractFileRef.fromJson(item.cast<String, dynamic>());
    }
    throw Exception('Unexpected contract file payload');
  }

  Future<List<ClientContract>> list(String clientId) async {
    final r = await AuthenticatedHttpClient.get(
      _u(clientId),
      headers: _headers(),
    );
    return _decode<List<ClientContract>>(r, _mapContracts);
  }

  Future<ClientContract> getById(String clientId, String contractId) async {
    final r = await AuthenticatedHttpClient.get(
      _u(clientId, '/$contractId'),
      headers: _headers(),
    );
    return _decode<ClientContract>(r, _mapContract);
  }

  Future<ClientContract> upload({
    required String clientId,
    required List<int> fileBytes,
    required String fileName,
    String? title,
    String? contractType,
    String? status,
    String? startDate,
    String? endDate,
    String? renewalDate,
    String? signedAt,
    String? notes,
    List<String>? tags,
    String? version,
    bool? isCurrent,
  }) async {
    final request = http.MultipartRequest('POST', _u(clientId));
    request.headers.addAll(
      await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: false,
      ),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType('application', 'pdf'),
      ),
    );
    void putField(String key, String? value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) request.fields[key] = trimmed;
    }

    putField('title', title);
    putField('contractType', contractType);
    putField('status', status);
    putField('startDate', startDate);
    putField('endDate', endDate);
    putField('renewalDate', renewalDate);
    putField('signedAt', signedAt);
    putField('notes', notes);
    if (tags != null && tags.isNotEmpty) {
      request.fields['tags'] = jsonEncode(tags);
    }
    putField('version', version);
    if (isCurrent != null) {
      request.fields['isCurrent'] = isCurrent.toString();
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode<ClientContract>(response, _mapContract);
  }

  Future<ClientContract> update({
    required String clientId,
    required String contractId,
    required Map<String, dynamic> fields,
  }) async {
    final sanitized = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = entry.value;
      if (value == null) {
        sanitized[entry.key] = null;
      } else if (value is String) {
        sanitized[entry.key] = value.trim().isEmpty ? null : value.trim();
      } else {
        sanitized[entry.key] = value;
      }
    }
    final r = await AuthenticatedHttpClient.patch(
      _u(clientId, '/$contractId'),
      headers: _headers(),
      body: jsonEncode(sanitized),
    );
    return _decode<ClientContract>(r, _mapContract);
  }

  Future<void> delete(String clientId, String contractId) async {
    final r = await AuthenticatedHttpClient.delete(
      _u(clientId, '/$contractId'),
      headers: _headers(),
    );
    _decode<void>(r, (_) {});
  }

  Future<ClientContractFileRef> getFile(
    String clientId,
    String contractId,
  ) async {
    final r = await AuthenticatedHttpClient.get(
      _u(clientId, '/$contractId/file'),
      headers: _headers(),
    );
    return _decode<ClientContractFileRef>(r, _mapFile);
  }
}
