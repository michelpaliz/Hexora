import 'package:shared_preferences/shared_preferences.dart';

class InsightsHistoryStore {
  InsightsHistoryStore._();

  static const keyPrefix = 'insights_chat_history::';
  static int _sessionVersion = 0;

  static int get sessionVersion => _sessionVersion;

  static Future<void> clearForSignedOutSession() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = preferences
        .getKeys()
        .where((key) => key.startsWith(keyPrefix))
        .toList(growable: false);
    for (final key in keys) {
      await preferences.remove(key);
    }
    _sessionVersion += 1;
  }
}
