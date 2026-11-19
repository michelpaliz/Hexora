import 'package:flutter/foundation.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-scoped presentation preferences that must not be shared by a business.
class UserPreferencesProvider extends ChangeNotifier {
  static const _legacyCompactKey = 'dashboard_top_nav_compact_v2';
  static const _legacyMigrationOwnerKey =
      'dashboard_top_nav_compact_migration_owner';
  static const _navigationKey = 'navigation_display_mode';
  static const _topNavCollapsedKey = 'top_nav_collapsed';

  String? _userId;
  int _loadVersion = 0;
  bool _loaded = false;
  NavigationDisplayMode _navigationDisplayMode =
      NavigationDisplayMode.automatic;
  // Visibility of the global top navigation. Independent from the display mode
  // above: a user can collapse the bar in any Automatic/Icons/Text mode.
  bool _topNavCollapsed = false;

  bool get isLoaded => _loaded;
  String? get userId => _userId;
  NavigationDisplayMode get navigationDisplayMode => _navigationDisplayMode;
  bool get topNavCollapsed => _topNavCollapsed;

  Future<void> bindUser(String? userId) async {
    final normalized = userId?.trim();
    final nextUserId =
        normalized == null || normalized.isEmpty ? null : normalized;
    if (_userId == nextUserId) return;

    _userId = nextUserId;
    _loaded = nextUserId == null;
    _navigationDisplayMode = NavigationDisplayMode.automatic;
    _topNavCollapsed = false;
    final version = ++_loadVersion;
    notifyListeners();
    if (nextUserId == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      if (version != _loadVersion) return;
      final stored = preferences.getString(_keyFor(nextUserId));
      if (stored != null) {
        _navigationDisplayMode = _modeFromStorage(stored);
      } else {
        // Claim the old device-wide value once. New users always get Automatic.
        final migrationOwner = preferences.getString(_legacyMigrationOwnerKey);
        final canMigrate = migrationOwner == null &&
            preferences.containsKey(_legacyCompactKey);
        final wasCompact = preferences.getBool(_legacyCompactKey) ?? false;
        _navigationDisplayMode = canMigrate && wasCompact
            ? NavigationDisplayMode.iconsOnly
            : NavigationDisplayMode.automatic;
        await preferences.setString(
          _keyFor(nextUserId),
          _modeToStorage(_navigationDisplayMode),
        );
        if (canMigrate) {
          await preferences.setString(_legacyMigrationOwnerKey, nextUserId);
        }
      }
      _topNavCollapsed =
          preferences.getBool(_collapsedKeyFor(nextUserId)) ?? false;
    } catch (error) {
      debugPrint('[UserPreferencesProvider] load failed: $error');
      _navigationDisplayMode = NavigationDisplayMode.automatic;
      _topNavCollapsed = false;
    } finally {
      if (version == _loadVersion) {
        _loaded = true;
        notifyListeners();
      }
    }
  }

  Future<void> setNavigationDisplayMode(
    NavigationDisplayMode mode,
  ) async {
    if (_navigationDisplayMode == mode) return;
    _navigationDisplayMode = mode;
    notifyListeners();

    final currentUserId = _userId;
    if (currentUserId == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_userId != currentUserId) return;
      await preferences.setString(
        _keyFor(currentUserId),
        _modeToStorage(mode),
      );
    } catch (error) {
      debugPrint('[UserPreferencesProvider] save failed: $error');
    }
  }

  Future<void> setTopNavCollapsed(bool collapsed) async {
    if (_topNavCollapsed == collapsed) return;
    _topNavCollapsed = collapsed;
    notifyListeners();

    final currentUserId = _userId;
    if (currentUserId == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_userId != currentUserId) return;
      await preferences.setBool(_collapsedKeyFor(currentUserId), collapsed);
    } catch (error) {
      debugPrint('[UserPreferencesProvider] save failed: $error');
    }
  }

  static String _keyFor(String userId) => 'hexora.user.$userId.$_navigationKey';

  static String _collapsedKeyFor(String userId) =>
      'hexora.user.$userId.$_topNavCollapsedKey';

  static String _modeToStorage(NavigationDisplayMode mode) => mode.name;

  static NavigationDisplayMode _modeFromStorage(String value) {
    return NavigationDisplayMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => NavigationDisplayMode.automatic,
    );
  }
}
