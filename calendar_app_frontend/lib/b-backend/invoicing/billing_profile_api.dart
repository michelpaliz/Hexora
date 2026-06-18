import 'dart:convert';

import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class BillingProfileApi {
  final String _base = '${ApiConstants.baseUrl}/billing-profiles';

  Map<String, String> _headers() => {
        'Content-Type': 'application/json; charset=UTF-8',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

  Uri _logoUploadUri(String groupId) =>
      Uri.parse('$_base/group/$groupId/logo/upload');

  T _decode<T>(http.Response r, T Function(dynamic) map) {
    final ok = r.statusCode >= 200 && r.statusCode < 300;
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(r.body);
      } catch (_) {
        body = r.body;
      }
    }

    if (ok) return map(body);

    String message = r.reasonPhrase ?? 'Request failed';
    if (body is Map && body['message'] != null) {
      message = body['message'].toString();
    } else if (body is Map && body['error'] != null) {
      message = body['error'].toString();
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<BillingProfile> upsert(BillingProfile profile) async {
    final r = await AuthenticatedHttpClient.post(
      _u(),
      headers: _headers(),
      body: jsonEncode(profile.toPayload()),
    );
    return _decode<BillingProfile>(r, (j) => BillingProfile.fromJson(j));
  }

  Future<BillingProfile?> getByGroup(String groupId) async {
    final r = await AuthenticatedHttpClient.get(
      _u('/group/$groupId'),
      headers: _headers(),
    );
    if (r.statusCode == 404) return null;
    return _decode<BillingProfile?>(r, (j) {
      if (j == null) return null;
      if (j is Map<String, dynamic>) return BillingProfile.fromJson(j);
      throw Exception('Unexpected billing profile payload');
    });
  }

  Future<BillingProfile> updateLogo({
    required String groupId,
    required String logoUrl,
  }) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/group/$groupId/logo'),
      headers: _headers(),
      body: jsonEncode({'logoUrl': logoUrl}),
    );
    return _decode<BillingProfile>(r, (j) {
      if (j is Map<String, dynamic>) return BillingProfile.fromJson(j);
      throw Exception('Unexpected billing profile payload');
    });
  }

  Future<BillingProfile> uploadLogo({
    required String groupId,
    required String filename,
    required List<int> bytes,
  }) async {
    final r = http.MultipartRequest('POST', _logoUploadUri(groupId));
    r.headers.addAll(
      await AuthenticatedHttpClient.authorizedHeaders(
        includeJsonContentType: false,
      ),
    );
    r.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));
    final streamed = await r.send();
    final response = await http.Response.fromStream(streamed);
    return _decode<BillingProfile>(response, (j) {
      if (j is Map<String, dynamic>) return BillingProfile.fromJson(j);
      throw Exception('Unexpected billing profile payload');
    });
  }

  Future<BillingProfile> updateWebsite({
    required String groupId,
    required String website,
  }) async {
    final r = await AuthenticatedHttpClient.patch(
      _u('/group/$groupId/website'),
      headers: _headers(),
      body: jsonEncode({'website': website}),
    );
    return _decode<BillingProfile>(r, (j) {
      if (j is Map<String, dynamic>) return BillingProfile.fromJson(j);
      throw Exception('Unexpected billing profile payload');
    });
  }
}
