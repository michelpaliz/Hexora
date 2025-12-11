import 'package:flutter/foundation.dart';

// lib/utilities/constants/api_constants.dart

// How it works now
// If avatarsArePublic = true, it skips the extra /read-sas request and builds the URL directly from your CDN.
// If avatarsArePublic = false, it requests a read-SAS for private blobs.
// You can flip the flag anytime without touching the rest of your code.

class ApiConstants {
  static const String _envBase = String.fromEnvironment('BASE_URL');
  static const String _envCdn = String.fromEnvironment('CDN_BASE_URL');

  /// Backend API base URL; defaults to relative on web (hosted), localhost in dev,
  /// or an explicit dart-define when provided.
  static const String baseUrl = _envBase != ''
      ? _envBase
      : (kIsWeb ? '/api' : 'http://localhost:3000/api');

  /// Base URL for public blob access via CDN
  static const String cdnBaseUrl =
      _envCdn != '' ? _envCdn : 'https://cdn.fastezcode.com/profile-images';

  /// If true, avatars are public and served from CDN;
  /// if false, must fetch short-lived read-SAS from API.
  static const bool avatarsArePublic = true;
}
