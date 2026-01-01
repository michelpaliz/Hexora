import 'package:shared_preferences/shared_preferences.dart';

class EnableBankingLinkStatus {
  final bool? linked;
  final String? sessionId;
  final String? error;
  final DateTime? updatedAt;

  const EnableBankingLinkStatus({
    required this.linked,
    required this.sessionId,
    required this.error,
    required this.updatedAt,
  });

  bool get hasValue =>
      linked != null || (sessionId != null && sessionId!.isNotEmpty) || error != null;
}

class EnableBankingLinkStore {
  static const _kLinked = 'enable_banking.linked';
  static const _kSessionId = 'enable_banking.session_id';
  static const _kError = 'enable_banking.error';
  static const _kUpdatedAtMillis = 'enable_banking.updated_at_ms';

  static Future<void> save({
    required bool? linked,
    required String? sessionId,
    required String? error,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (linked == null) {
      await prefs.remove(_kLinked);
    } else {
      await prefs.setBool(_kLinked, linked);
    }
    if (sessionId == null || sessionId.isEmpty) {
      await prefs.remove(_kSessionId);
    } else {
      await prefs.setString(_kSessionId, sessionId);
    }
    if (error == null || error.isEmpty) {
      await prefs.remove(_kError);
    } else {
      await prefs.setString(_kError, error);
    }
    await prefs.setInt(_kUpdatedAtMillis, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<EnableBankingLinkStatus> load() async {
    final prefs = await SharedPreferences.getInstance();
    final linked = prefs.containsKey(_kLinked) ? prefs.getBool(_kLinked) : null;
    final sessionId = prefs.getString(_kSessionId);
    final error = prefs.getString(_kError);
    final updatedAtMs = prefs.getInt(_kUpdatedAtMillis);
    return EnableBankingLinkStatus(
      linked: linked,
      sessionId: sessionId,
      error: error,
      updatedAt: updatedAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(updatedAtMs),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLinked);
    await prefs.remove(_kSessionId);
    await prefs.remove(_kError);
    await prefs.remove(_kUpdatedAtMillis);
  }
}

