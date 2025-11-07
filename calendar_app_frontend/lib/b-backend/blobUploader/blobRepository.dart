import 'dart:convert';
import 'dart:io';

import 'package:hexora/b-backend/auth_user/auth/token/service/token_service.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';
import 'package:http/http.dart' as http;

/// Returned by commit methods (final URL + blob key saved in DB)
class CommittedPhoto {
  final String photoUrl;
  final String blobName;
  const CommittedPhoto({required this.photoUrl, required this.blobName});
}

class BlobRepository {
  Future<String?> _token() => TokenService.loadToken();

  /// Uploads to Azure (via SAS) and commits to /users/me/photo.
  Future<CommittedPhoto> uploadUserAvatar({required File file}) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');

    // 1) upload to Azure
    final up = await uploadImageToAzure(
      scope: 'users',
      file: file,
      accessToken: token,
    );

    // 2) commit blobName to backend
    final resp = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'blobName': up.blobName}),
    );

    if (resp.statusCode != 200) {
      throw Exception('Commit avatar failed: ${resp.statusCode} ${resp.body}');
    }

    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final url = (map['photoUrl'] as String?) ?? up.photoUrl;
    final blob = (map['photoBlobName'] as String?) ?? up.blobName;
    return CommittedPhoto(photoUrl: url, blobName: blob);
  }

  /// Uploads to Azure (via SAS) and commits to /groups/{id}/photo.
  Future<CommittedPhoto> uploadGroupPhoto({
    required String groupId,
    required File file,
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Not authenticated');

    // 1) upload to Azure
    final up = await uploadImageToAzure(
      scope: 'groups',
      resourceId: groupId,
      file: file,
      accessToken: token,
    );

    // 2) commit blobName to backend
    final resp = await http.patch(
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/photo'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'blobName': up.blobName}),
    );

    if (resp.statusCode != 200) {
      throw Exception(
          'Commit group photo failed: ${resp.statusCode} ${resp.body}');
    }

    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final url = (map['photoUrl'] as String?) ?? up.photoUrl;
    final blob = (map['photoBlobName'] as String?) ?? up.blobName;
    return CommittedPhoto(photoUrl: url, blobName: blob);
  }
}
