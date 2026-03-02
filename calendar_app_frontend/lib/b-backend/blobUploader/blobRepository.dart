import 'dart:convert';
import 'dart:io';

import 'package:hexora/b-backend/auth_user/auth/token/service/authenticated_http_client.dart';
import 'package:hexora/b-backend/blobUploader/blobServer.dart';
import 'package:hexora/b-backend/config/api_constants.dart';

/// Returned by commit methods (final URL + blob key saved in DB)
class CommittedPhoto {
  final String photoUrl;
  final String blobName;
  const CommittedPhoto({required this.photoUrl, required this.blobName});
}

class BlobRepository {
  Future<String> _accessToken() async {
    final headers = await AuthenticatedHttpClient.authorizedHeaders(
      includeJsonContentType: false,
    );
    final auth = headers['Authorization'] ?? '';
    if (!auth.startsWith('Bearer ')) {
      throw Exception('Not authenticated');
    }
    final token = auth.substring('Bearer '.length).trim();
    if (token.isEmpty) throw Exception('Not authenticated');
    return token;
  }

  /// Uploads to Azure (via SAS) and commits to /users/me/photo.
  Future<CommittedPhoto> uploadUserAvatar({required File file}) async {
    final token = await _accessToken();

    // 1) upload to Azure
    final up = await uploadImageToAzure(
      scope: 'users',
      file: file,
      accessToken: token,
    );

    // 2) commit blobName to backend
    final resp = await AuthenticatedHttpClient.patch(
      Uri.parse('${ApiConstants.baseUrl}/users/me/photo'),
      headers: {
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
    final token = await _accessToken();

    // 1) upload to Azure
    final up = await uploadImageToAzure(
      scope: 'groups',
      resourceId: groupId,
      file: file,
      accessToken: token,
    );

    // 2) commit blobName to backend
    final resp = await AuthenticatedHttpClient.patch(
      Uri.parse('${ApiConstants.baseUrl}/groups/$groupId/photo'),
      headers: {
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
