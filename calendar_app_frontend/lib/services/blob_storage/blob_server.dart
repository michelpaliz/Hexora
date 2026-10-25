// lib/services/api/blob/blob_uploader.dart
import 'dart:convert';
import 'dart:io';

import 'package:hexora/services/config/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UploadResult {
  final String photoUrl; // URL to display in UI
  final String blobName; // Store in DB as photoBlobName
  UploadResult({required this.photoUrl, required this.blobName});
}

String? detectImageMimeType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4e &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0d &&
      bytes[5] == 0x0a &&
      bytes[6] == 0x1a &&
      bytes[7] == 0x0a) {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

class BlobUploadException implements Exception {
  final String stage;
  final String method;
  final Uri url;
  final int? statusCode;
  final String? responseBody;
  final Map<String, String>? responseHeaders;
  final Object? innerError;

  const BlobUploadException({
    required this.stage,
    required this.method,
    required this.url,
    this.statusCode,
    this.responseBody,
    this.responseHeaders,
    this.innerError,
  });

  @override
  String toString() {
    final parts = <String>[
      'stage=$stage',
      'method=$method',
      'url=$url',
      if (statusCode != null) 'statusCode=$statusCode',
      if (innerError != null) 'innerError=$innerError',
      if (responseBody != null && responseBody!.isNotEmpty)
        'responseBody=$responseBody',
    ];
    return 'BlobUploadException(${parts.join(' ')})';
  }
}

/// scope: 'users' | 'groups'
/// resourceId: required when scope == 'groups' (the groupId)
Future<UploadResult> uploadImageToAzure({
  required String scope, // 'users' | 'groups'
  String? resourceId, // groupId when scope == 'groups'
  File? file,
  Uint8List? bytes,
  required String accessToken,
  String mimeType = 'image/jpeg',
  bool avatarsArePublic = ApiConstants.avatarsArePublic,
}) async {
  if (scope == 'groups' && (resourceId == null || resourceId.isEmpty)) {
    throw ArgumentError(
        'resourceId (groupId) is required when scope == "groups"');
  }
  if (file == null && bytes == null) {
    throw ArgumentError('Either file or bytes must be provided');
  }
  final contentBytes = bytes ?? await file!.readAsBytes();
  final uploadMimeType = mimeType.startsWith('image/')
      ? detectImageMimeType(contentBytes)
      : mimeType;
  if (uploadMimeType == null) throw ArgumentError('Unsupported image content');
  if (mimeType.startsWith('image/') && contentBytes.length > 10 * 1024 * 1024) {
    throw ArgumentError('Image must be 10 MB or smaller');
  }

  // --- 1) Get upload SAS ---
  final String sasEndpoint = (scope == 'users')
      ? '${ApiConstants.baseUrl}/blob/users/me/upload-sas'
      : '${ApiConstants.baseUrl}/blob/groups/$resourceId/upload-sas';

  final sasUri = Uri.parse(sasEndpoint);
  late final http.Response sasResp;
  try {
    sasResp = await http.post(
      sasUri,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mimeType': uploadMimeType,
        'strategy': 'versioned',
      }),
    );
  } catch (e) {
    throw BlobUploadException(
      stage: 'get-upload-sas',
      method: 'POST',
      url: sasUri,
      innerError: e,
    );
  }
  if (sasResp.statusCode != 200) {
    if (kDebugMode) {
      debugPrint(
        '[BlobUploader] POST $sasUri -> ${sasResp.statusCode} '
        'body=${sasResp.body}',
      );
    }
    throw BlobUploadException(
      stage: 'get-upload-sas',
      method: 'POST',
      url: sasUri,
      statusCode: sasResp.statusCode,
      responseBody: sasResp.body,
      responseHeaders: sasResp.headers,
    );
  }
  late final Map<String, dynamic> sasData;
  try {
    sasData = jsonDecode(sasResp.body) as Map<String, dynamic>;
  } catch (e) {
    throw BlobUploadException(
      stage: 'parse-upload-sas',
      method: 'POST',
      url: sasUri,
      statusCode: sasResp.statusCode,
      responseBody: sasResp.body,
      responseHeaders: sasResp.headers,
      innerError: e,
    );
  }
  final uploadUrl = sasData['uploadUrl'] as String;
  final blobName = sasData['blobName'] as String;

  // --- 2) Upload to Azure ---
  final uploadUri = Uri.parse(uploadUrl);
  late final http.Response putResp;
  try {
    putResp = await http.put(
      uploadUri,
      headers: {
        'x-ms-blob-type': 'BlockBlob',
        'Content-Type': uploadMimeType,
      },
      body: contentBytes,
    );
  } catch (e) {
    throw BlobUploadException(
      stage: 'azure-upload',
      method: 'PUT',
      url: uploadUri,
      innerError: e,
    );
  }
  if (putResp.statusCode != 201 && putResp.statusCode != 200) {
    if (kDebugMode) {
      debugPrint(
        '[BlobUploader] PUT $uploadUri -> ${putResp.statusCode} '
        'body=${putResp.body}',
      );
    }
    throw BlobUploadException(
      stage: 'azure-upload',
      method: 'PUT',
      url: uploadUri,
      statusCode: putResp.statusCode,
      responseBody: putResp.body,
      responseHeaders: putResp.headers,
    );
  }

  // --- 3) Get display URL ---
  String viewUrl;
  if (avatarsArePublic) {
    // ✅ Use blobUrl from backend if provided
    final fromBackend = sasData['blobUrl'] as String?;
    if (fromBackend != null && fromBackend.isNotEmpty) {
      viewUrl = fromBackend;
    } else {
      // Fallback if backend didn't send it (unlikely)
      viewUrl = '${ApiConstants.cdnBaseUrl}/$blobName';
    }
  } else {
    final String readEndpoint = (scope == 'users')
        ? '${ApiConstants.baseUrl}/blob/users/me/read-sas?blobName=${Uri.encodeComponent(blobName)}'
        : '${ApiConstants.baseUrl}/blob/groups/$resourceId/read-sas?blobName=${Uri.encodeComponent(blobName)}';

    final readUri = Uri.parse(readEndpoint);
    late final http.Response readResp;
    try {
      readResp = await http.get(
        readUri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } catch (e) {
      throw BlobUploadException(
        stage: 'get-read-sas',
        method: 'GET',
        url: readUri,
        innerError: e,
      );
    }
    if (readResp.statusCode != 200) {
      if (kDebugMode) {
        debugPrint(
          '[BlobUploader] GET $readUri -> ${readResp.statusCode} '
          'body=${readResp.body}',
        );
      }
      throw BlobUploadException(
        stage: 'get-read-sas',
        method: 'GET',
        url: readUri,
        statusCode: readResp.statusCode,
        responseBody: readResp.body,
        responseHeaders: readResp.headers,
      );
    }
    late final Map<String, dynamic> readData;
    try {
      readData = jsonDecode(readResp.body) as Map<String, dynamic>;
    } catch (e) {
      throw BlobUploadException(
        stage: 'parse-read-sas',
        method: 'GET',
        url: readUri,
        statusCode: readResp.statusCode,
        responseBody: readResp.body,
        responseHeaders: readResp.headers,
        innerError: e,
      );
    }
    viewUrl = (readData['url'] as String?) ?? '';
    if (viewUrl.isEmpty) {
      throw BlobUploadException(
        stage: 'parse-read-sas',
        method: 'GET',
        url: readUri,
        statusCode: readResp.statusCode,
        responseBody: readResp.body,
        responseHeaders: readResp.headers,
        innerError: 'Read-SAS response missing URL',
      );
    }
  }

  return UploadResult(photoUrl: viewUrl, blobName: blobName);
}
