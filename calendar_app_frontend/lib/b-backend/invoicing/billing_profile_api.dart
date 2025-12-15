import 'dart:convert';

import 'package:hexora/a-models/invoice/billing_profile.dart';
import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class BillingProfileApi {
  final String _base = '${ApiConstants.baseUrl}/billing-profiles';

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer ${await TokenService.loadToken()}',
      };

  Uri _u([String path = '']) => Uri.parse('$_base$path');

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
    } else if (body is String && body.trim().isNotEmpty) {
      message = body.trim();
    }
    throw Exception(message);
  }

  Future<BillingProfile> upsert(BillingProfile profile) async {
    final r = await http.post(
      _u(),
      headers: await _headers(),
      body: jsonEncode(profile.toPayload()),
    );
    return _decode<BillingProfile>(r, (j) => BillingProfile.fromJson(j));
  }

  Future<BillingProfile?> getByGroup(String groupId) async {
    final r = await http.get(_u('/group/$groupId'), headers: await _headers());
    if (r.statusCode == 404) return null;
    return _decode<BillingProfile?>(r, (j) {
      if (j == null) return null;
      if (j is Map<String, dynamic>) return BillingProfile.fromJson(j);
      throw Exception('Unexpected billing profile payload');
    });
  }
}
