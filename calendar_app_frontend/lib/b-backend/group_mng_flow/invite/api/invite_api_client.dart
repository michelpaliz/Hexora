import 'dart:convert';
import 'package:hexora/a-models/group_model/invite/invite.dart';
import 'package:http/http.dart' as http;
import 'package:hexora/b-backend/config/api_constants.dart';

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
    throw Exception('Failed to create invitation: ${res.statusCode} ${res.reasonPhrase}');
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
    throw Exception('Failed to fetch group invitations: ${res.statusCode} ${res.reasonPhrase}');
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
    throw Exception('Failed to fetch my invitations: ${res.statusCode} ${res.reasonPhrase}');
  }

  Future<Invitation> accept(String invitationId, {required String token, String? note}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/accept'),
      headers: _headers(token: token),
      body: jsonEncode({'note': note}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) throw Exception('Invitation not found');
    throw Exception('Failed to accept: ${res.statusCode} ${res.reasonPhrase}');
  }

  Future<Invitation> decline(String invitationId, {required String token, String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/decline'),
      headers: _headers(token: token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) throw Exception('Invitation not found');
    throw Exception('Failed to decline: ${res.statusCode} ${res.reasonPhrase}');
  }

  Future<Invitation> resend(String invitationId, {required String token}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/resend'),
      headers: _headers(token: token),
      body: jsonEncode({}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) throw Exception('Invitation not found');
    throw Exception('Failed to resend: ${res.statusCode} ${res.reasonPhrase}');
  }

  Future<Invitation> revoke(String invitationId, {required String token, String? reason}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$invitationId/revoke'),
      headers: _headers(token: token),
      body: jsonEncode({'reason': reason}),
    );
    if (res.statusCode == 200) return Invitation.fromJson(jsonDecode(res.body));
    if (res.statusCode == 404) throw Exception('Invitation not found');
    throw Exception('Failed to revoke: ${res.statusCode} ${res.reasonPhrase}');
  }
}
