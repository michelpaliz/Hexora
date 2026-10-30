import 'package:shared_preferences/shared_preferences.dart';

/// Stores only an identifier. Group data and access are verified on every reload.
class LastGroupSelection {
  static String _key(String userId) => 'hexora.last_group.$userId';

  static Future<void> save(String userId, String groupId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key(userId), groupId);
  }

  static Future<String?> load(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_key(userId));
  }

  static Future<void> clear(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(userId));
  }
}
