import 'dart:convert';

import 'package:hexora/b-backend/auth_user/api/i_auth_api_client.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

class AuthApiClientImpl implements IAuthApiClient {
  final String _base = ApiConstants.baseUrl;

  Map<String, String> _headers({String? token}) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  @override
  Future<Map<String, dynamic>> register({
    required String name,
    required String userName,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: _headers(),
      body: jsonEncode({
        'name': name,
        'userName': userName,
        'email': email,
        'password': password,
      }),
    );
    return _decode(res);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _decode(res);
  }

  @override
  Future<Map<String, dynamic>> profile({required String accessToken}) async {
    final res = await http.get(
      Uri.parse('$_base/auth/profile'),
      headers: _headers(token: accessToken),
    );
    return _decode(res);
  }

  @override
  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final res = await http.post(
      Uri.parse('$_base/auth/refresh'),
      headers: _headers(),
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return _decode(res);
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/auth/change-password'),
      headers: _headers(token: accessToken),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Password change failed: ${res.statusCode} ${res.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyEmail({required String token}) async {
    final res = await http.get(
      Uri.parse('$_base/auth/verify-email?token=$token'),
      headers: _headers(),
    );
    return _decode(res);
  }

  @override
  Future<Map<String, dynamic>> resendVerification(
      {required String email}) async {
    final res = await http.post(
      Uri.parse('$_base/auth/resend-verification'),
      headers: _headers(),
      body: jsonEncode({'email': email}),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = res.body.isEmpty ? '{}' : res.body;
    final json = jsonDecode(body);
    // Surface non-200s to callers so they can map to exceptions
    if (res.statusCode < 200 || res.statusCode >= 300) {
      return {
        '_status': res.statusCode,
        '_error': true,
        ..._coerceMap(json),
      };
    }
    return _coerceMap(json);
  }

  Map<String, dynamic> _coerceMap(dynamic v) =>
      (v is Map<String, dynamic>) ? v : <String, dynamic>{'data': v};
}
