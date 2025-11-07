import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hexora/b-backend/auth_user/auth/token/model/token_obj.dart';
import 'package:hexora/b-backend/auth_user/auth/token/token_store/Itoken_store.dart';

/// Secure implementation backed by FlutterSecureStorage
class SecureTokenStore implements TokenStore {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  final FlutterSecureStorage _storage;
  final IOSOptions _iosOptions;
  final AndroidOptions _androidOptions;
  final LinuxOptions _linuxOptions;
  final WebOptions? _webOptions;

  // Optional in-memory cache to reduce I/O
  String? _cachedAccess;
  String? _cachedRefresh;

  SecureTokenStore({
    FlutterSecureStorage? storage,
    IOSOptions? iosOptions,
    AndroidOptions? androidOptions,
    LinuxOptions? linuxOptions,
    WebOptions? webOptions,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _iosOptions = iosOptions ??
            const IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
        _androidOptions = androidOptions ??
            const AndroidOptions(
              encryptedSharedPreferences: true,
              resetOnError: true,
            ),
        _linuxOptions = linuxOptions ?? const LinuxOptions(),
        _webOptions = webOptions;

  @override
  Future<void> save(AuthTokens tokens) async {
    // Write refresh first, then access, so a partially-written state still has a valid refresh.
    await _write(_kRefresh, tokens.refresh);
    await _write(_kAccess, tokens.access);
    _cachedAccess = tokens.access;
    _cachedRefresh = tokens.refresh;

    if (kDebugMode) {
      // Safe log (no secrets)
      debugPrint('[TokenStore] tokens saved (redacted)');
    }
  }

  @override
  Future<String?> readAccess() async {
    if (_cachedAccess != null) return _cachedAccess;
    final v = await _read(_kAccess);
    _cachedAccess = v;
    return v;
  }

  @override
  Future<String?> readRefresh() async {
    if (_cachedRefresh != null) return _cachedRefresh;
    final v = await _read(_kRefresh);
    _cachedRefresh = v;
    return v;
  }

  @override
  Future<AuthTokens?> readBoth() async {
    final a = await readAccess();
    final r = await readRefresh();
    if (a == null || r == null) return null;
    return AuthTokens(access: a, refresh: r);
  }

  @override
  Future<void> clear() async {
    await _delete(_kAccess);
    await _delete(_kRefresh);
    _cachedAccess = null;
    _cachedRefresh = null;
    if (kDebugMode) debugPrint('[TokenStore] tokens cleared');
  }

  Future<void> _write(String key, String value) {
    return _storage.write(
      key: key,
      value: value,
      iOptions: _iosOptions,
      aOptions: _androidOptions,
      lOptions: _linuxOptions,
      webOptions: _webOptions,
    );
  }

  Future<String?> _read(String key) {
    return _storage.read(
      key: key,
      iOptions: _iosOptions,
      aOptions: _androidOptions,
      lOptions: _linuxOptions,
      webOptions: _webOptions,
    );
  }

  Future<void> _delete(String key) {
    return _storage.delete(
      key: key,
      iOptions: _iosOptions,
      aOptions: _androidOptions,
      lOptions: _linuxOptions,
      webOptions: _webOptions,
    );
  }
}
