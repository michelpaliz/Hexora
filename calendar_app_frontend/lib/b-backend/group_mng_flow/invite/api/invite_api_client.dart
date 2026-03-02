import 'dart:convert';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:http/http.dart' as http;
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:hexora/b-backend/shared/backend_api_exception.dart';

// -----------------------------------------------------------------------------
// API CLIENT (low-level HTTP, mirrors your Express routes)
// -----------------------------------------------------------------------------
class InvitationApiClient {
  final String baseUrl = '${ApiConstants.baseUrl}/invitations';

  Map<String, String> _headers({String? token, Map<String, String>? extra}) => {
        'Content-Type': 'application/json; charset=UTF-8',
        if (token != null) 'Authorization': 'Bearer $token',
        ...?extra,
      };

  Never _throwApiError(http.Response res, String fallbackMessage) {
    throw BackendApiException.fromResponse(
      res,
      fallbackMessage: fallbackMessage,
    );
  }

  Future<Invitation> create({
    required String groupId,
    String? email,
    String? userId,
    String? role, // member | co-admin | admin
    String? message,
    required String token,
    Map<String, dynamic>? extra,
  }) async {
    final payload = {
      'groupId': groupId,
      if (email != null) 'email': email,
      if (userId != null) 'userId': userId,
      if (role != null) 'role': role,
      if (message != null) 'message': message,
      ...?extra,
    };
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: _headers(token: token),
      body: jsonEncode(payload),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Invitation.fromJson(jsonDecode(res.body));
    }
    _throwApiError(res, 'Failed to create invitation');
  }

  Future<List<Invitation>> listGroupInvitations(String groupId, {required String token}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/group/$groupId'),
      headers: _headers(token: token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data is List ? data : (data['invitations'] as List?)) ?? [];
      return list.map<Invitation>((e) => Invitation.fromJson(e)).toList();
    }
    _throwApiError(res, 'Failed to fetch group invitations');
  }

  Future<List<Invitation>> listMyInvitations({required String token, String? userId, String? email}) async {
    final uri = Uri.parse('$baseUrl/me').replace(queryParameters: {
      if (userId != null) 'userId': userId,
      if (email != null) 'email': email,
    });
    final res = await http.get(uri, headers: _headers(token: token));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = (data is List ? data : (data['invitations'] as List?)) ?? [];
      return list.map<Invitation>((e) => Invitation.fromJson(e)).toList();
    }
    _throwApiError(res, 'Failed to fetch my invitations');
  }

  Future<Invitation> accept(String invitationId, {required String token, String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/accept'),
      headers: _headers(token: token),
      body: jsonEncode({'note': note}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    _throwApiError(res, 'Failed to accept invitation');
  }

  Future<Invitation> decline(String invitationId, {required String token, String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/decline'),
      headers: _headers(token: token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    _throwApiError(res, 'Failed to decline invitation');
  }

  Future<Invitation> resend(String invitationId, {required String token}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/resend'),
      headers: _headers(token: token),
      body: jsonEncode({}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    _throwApiError(res, 'Failed to resend invitation');
  }

  Future<Invitation> revoke(String invitationId, {required String token, String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/revoke'),
      headers: _headers(token: token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    _throwApiError(res, 'Failed to revoke invitation');
  }
}
