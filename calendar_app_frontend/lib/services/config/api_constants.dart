import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _envBase = String.fromEnvironment('API_BASE_URL');
  static const String _envCdn = String.fromEnvironment('CDN_BASE_URL');
  static const String _envSocket = String.fromEnvironment('SOCKET_BASE_URL');

  static String _normalizeBase(String value) {
    var v = value.trim();
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }

  /// Backend API base URL.
  /// Web default: relative `/api` (same origin).
  /// Native fallback: absolute production URL.
  static String get baseUrl {
    // On web:
    // - production hosts (hexora.dev) should use same-origin `/api`
    // - localhost/dev can use explicit API_BASE_URL when provided
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      final isLocal = host == 'localhost' ||
          host == '127.0.0.1' ||
          host == '::1' ||
          host.endsWith('.localhost');
      if (isLocal && _envBase.trim().isNotEmpty) {
        return _normalizeBase(_envBase);
      }
      return '/api';
    }
    if (_envBase.trim().isNotEmpty) return _normalizeBase(_envBase);
    return 'https://hexora.dev/api';
  }

  /// Base URL for public blob access via CDN.
  static String get cdnBaseUrl {
    if (_envCdn.trim().isNotEmpty) return _normalizeBase(_envCdn);
    return 'https://cdn.hexora.dev/profile-images';
  }

  /// Socket/WS origin (without `/api`).
  static String get socketBaseUrl {
    if (_envSocket.trim().isNotEmpty) return _normalizeBase(_envSocket);
    final api = baseUrl;
    if (api.startsWith('http://') || api.startsWith('https://')) {
      final uri = Uri.parse(api);
      return '${uri.scheme}://${uri.authority}';
    }
    if (kIsWeb) return Uri.base.origin;
    return 'https://hexora.dev';
  }

  /// If true, avatars are public and served from CDN;
  /// if false, must fetch short-lived read-SAS from API.
  static const bool avatarsArePublic = true;
}
