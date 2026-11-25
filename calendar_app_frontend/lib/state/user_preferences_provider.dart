import 'package:flutter/foundation.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/services/user/user_preferences_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef UserPreferencesLoader = Future<Map<String, dynamic>> Function();
typedef UserPreferencesUpdater = Future<void> Function(
  Map<String, dynamic> changes,
);

/// User-scoped presentation preferences that must not be shared by a business.
class UserPreferencesProvider extends ChangeNotifier {
  UserPreferencesProvider({
    UserPreferencesLoader? remoteLoader,
    UserPreferencesUpdater? remoteUpdater,
  })  : _remoteLoader = remoteLoader ?? UserPreferencesApi.load,
        _remoteUpdater = remoteUpdater ?? UserPreferencesApi.update;

  static const _legacyCompactKey = 'dashboard_top_nav_compact_v2';
  static const _legacyMigrationOwnerKey =
      'dashboard_top_nav_compact_migration_owner';
  static const _navigationKey = 'navigation_display_mode';
  static const _navigationLayoutKey = 'navigation_layout';
  static const _globalHeaderPositionKey = 'global_header_position';
  static const _topNavCollapsedKey = 'top_nav_collapsed';
  static const _legacyShowDailyQuoteKey = 'home_show_daily_quote';
  static const _legacyFavoriteBusinessesKey = 'business_favorites';
  static const _homeMigrationOwnerKey = 'home_preferences_migration_owner';
  static const defaultNavigationDisplayMode = NavigationDisplayMode.iconsOnly;
  static const defaultNavigationLayout = NavigationLayout.unified;
  static const defaultGlobalHeaderPosition = GlobalHeaderPosition.bottom;

  final UserPreferencesLoader _remoteLoader;
  final UserPreferencesUpdater _remoteUpdater;

  String? _userId;
  int _loadVersion = 0;
  bool _loaded = false;
  NavigationDisplayMode _navigationDisplayMode = defaultNavigationDisplayMode;
  NavigationLayout _navigationLayout = defaultNavigationLayout;
  GlobalHeaderPosition _globalHeaderPosition = defaultGlobalHeaderPosition;
  // Visibility of the global top navigation. Independent from the display mode
  // above: a user can collapse the bar in any Automatic/Icons/Text mode.
  bool _topNavCollapsed = false;
  bool _showDailyQuote = true;
  Set<String> _favoriteBusinessIds = <String>{};

  bool get isLoaded => _loaded;
  String? get userId => _userId;
  NavigationDisplayMode get navigationDisplayMode => _navigationDisplayMode;
  NavigationLayout get navigationLayout => _navigationLayout;
  GlobalHeaderPosition get globalHeaderPosition => _globalHeaderPosition;
  bool get topNavCollapsed => _topNavCollapsed;
  bool get showDailyQuote => _showDailyQuote;
  Set<String> get favoriteBusinessIds => Set.unmodifiable(_favoriteBusinessIds);

  Future<void> bindUser(String? userId) async {
    final normalized = userId?.trim();
    final nextUserId =
        normalized == null || normalized.isEmpty ? null : normalized;
    if (_userId == nextUserId) return;

    _userId = nextUserId;
    _loaded = nextUserId == null;
    _navigationDisplayMode = defaultNavigationDisplayMode;
    _navigationLayout = defaultNavigationLayout;
    _globalHeaderPosition = defaultGlobalHeaderPosition;
    _topNavCollapsed = false;
    _showDailyQuote = true;
    _favoriteBusinessIds = <String>{};
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
        // Claim the old device-wide value once. New users use the product
        // defaults without inheriting another account's device preference.
        final migrationOwner = preferences.getString(_legacyMigrationOwnerKey);
        final canMigrate = migrationOwner == null &&
            preferences.containsKey(_legacyCompactKey);
        final wasCompact = preferences.getBool(_legacyCompactKey) ?? false;
        _navigationDisplayMode = canMigrate && wasCompact
            ? NavigationDisplayMode.iconsOnly
            : defaultNavigationDisplayMode;
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
      _navigationLayout = _layoutFromStorage(
        preferences.getString(_layoutKeyFor(nextUserId)) ??
            defaultNavigationLayout.name,
      );
      _globalHeaderPosition = _headerPositionFromStorage(
        preferences.getString(_headerPositionKeyFor(nextUserId)) ??
            defaultGlobalHeaderPosition.name,
      );
      final homeMigrationOwner = preferences.getString(_homeMigrationOwnerKey);
      final canMigrateHome = homeMigrationOwner == null;
      _showDailyQuote = preferences.getBool(_quoteKeyFor(nextUserId)) ??
          (canMigrateHome
              ? preferences.getBool(_legacyShowDailyQuoteKey)
              : null) ??
          true;
      _favoriteBusinessIds = (preferences.getStringList(
                _favoritesKeyFor(nextUserId),
              ) ??
              (canMigrateHome
                  ? preferences.getStringList(_legacyFavoriteBusinessesKey)
                  : null) ??
              const <String>[])
          .toSet();
      await preferences.setBool(
        _quoteKeyFor(nextUserId),
        _showDailyQuote,
      );
      await preferences.setStringList(
        _favoritesKeyFor(nextUserId),
        _favoriteBusinessIds.toList(),
      );
      if (canMigrateHome) {
        await preferences.setString(_homeMigrationOwnerKey, nextUserId);
      }

      try {
        final remote = await _remoteLoader();
        if (version != _loadVersion) return;
        final remoteMode = remote['navigationDisplayMode'];
        final remoteLayout = remote['navigationLayout'];
        final remoteHeaderPosition = remote['globalHeaderPosition'];
        final remoteCollapsed = remote['topNavCollapsed'];
        final remoteShowDailyQuote = remote['showDailyQuote'];
        final remoteFavoriteBusinesses = remote['favoriteBusinessIds'];
        if (remoteMode is String) {
          _navigationDisplayMode = _modeFromStorage(remoteMode);
          await preferences.setString(
            _keyFor(nextUserId),
            _modeToStorage(_navigationDisplayMode),
          );
        }
        if (remoteLayout is String) {
          _navigationLayout = _layoutFromStorage(remoteLayout);
          await preferences.setString(
            _layoutKeyFor(nextUserId),
            _navigationLayout.name,
          );
        }
        if (remoteHeaderPosition is String) {
          _globalHeaderPosition =
              _headerPositionFromStorage(remoteHeaderPosition);
          await preferences.setString(
            _headerPositionKeyFor(nextUserId),
            _globalHeaderPosition.name,
          );
        }
        if (remoteCollapsed is bool) {
          _topNavCollapsed = remoteCollapsed;
          await preferences.setBool(
            _collapsedKeyFor(nextUserId),
            remoteCollapsed,
          );
        }
        if (remoteShowDailyQuote is bool) {
          _showDailyQuote = remoteShowDailyQuote;
          await preferences.setBool(
            _quoteKeyFor(nextUserId),
            remoteShowDailyQuote,
          );
        }
        if (remoteFavoriteBusinesses is List) {
          _favoriteBusinessIds = remoteFavoriteBusinesses
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toSet();
          await preferences.setStringList(
            _favoritesKeyFor(nextUserId),
            _favoriteBusinessIds.toList(),
          );
        }
        if (remoteMode == null ||
            remoteLayout == null ||
            remoteHeaderPosition == null ||
            remoteCollapsed == null ||
            remoteShowDailyQuote == null ||
            remoteFavoriteBusinesses == null) {
          await _remoteUpdater({
            if (remoteMode == null)
              'navigationDisplayMode': _modeToStorage(_navigationDisplayMode),
            if (remoteLayout == null)
              'navigationLayout': _navigationLayout.name,
            if (remoteHeaderPosition == null)
              'globalHeaderPosition': _globalHeaderPosition.name,
            if (remoteCollapsed == null) 'topNavCollapsed': _topNavCollapsed,
            if (remoteShowDailyQuote == null) 'showDailyQuote': _showDailyQuote,
            if (remoteFavoriteBusinesses == null)
              'favoriteBusinessIds': _favoriteBusinessIds.toList(),
          });
        }
      } catch (error) {
        debugPrint('[UserPreferencesProvider] remote load failed: $error');
      }
    } catch (error) {
      debugPrint('[UserPreferencesProvider] load failed: $error');
      _navigationDisplayMode = defaultNavigationDisplayMode;
      _navigationLayout = defaultNavigationLayout;
      _globalHeaderPosition = defaultGlobalHeaderPosition;
      _topNavCollapsed = false;
      _showDailyQuote = true;
      _favoriteBusinessIds = <String>{};
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
      await _remoteUpdater({
        'navigationDisplayMode': _modeToStorage(mode),
      });
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
      await _remoteUpdater({'topNavCollapsed': collapsed});
    } catch (error) {
      debugPrint('[UserPreferencesProvider] save failed: $error');
    }
  }

  Future<void> setNavigationLayout(NavigationLayout layout) async {
    if (_navigationLayout == layout) return;
    _navigationLayout = layout;
    notifyListeners();

    final currentUserId = _userId;
    if (currentUserId == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_userId != currentUserId) return;
      await preferences.setString(
        _layoutKeyFor(currentUserId),
        layout.name,
      );
      await _remoteUpdater({'navigationLayout': layout.name});
    } catch (error) {
      debugPrint('[UserPreferencesProvider] layout save failed: $error');
    }
  }

  Future<void> setGlobalHeaderPosition(GlobalHeaderPosition position) async {
    if (_globalHeaderPosition == position) return;
    _globalHeaderPosition = position;
    notifyListeners();

    final currentUserId = _userId;
    if (currentUserId == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_userId != currentUserId) return;
      await preferences.setString(
        _headerPositionKeyFor(currentUserId),
        position.name,
      );
      await _remoteUpdater({'globalHeaderPosition': position.name});
    } catch (error) {
      debugPrint(
          '[UserPreferencesProvider] header position save failed: $error');
    }
  }

  Future<void> setShowDailyQuote(bool value) async {
    if (_showDailyQuote == value) return;
    _showDailyQuote = value;
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      final currentUserId = _userId;
      if (currentUserId != null) {
        await preferences.setBool(_quoteKeyFor(currentUserId), value);
        await _remoteUpdater({'showDailyQuote': value});
      }
    } catch (error) {
      debugPrint(
          '[UserPreferencesProvider] quote preference save failed: $error');
    }
  }

  Future<void> toggleFavoriteBusiness(String businessId) async {
    final normalized = businessId.trim();
    if (normalized.isEmpty) return;
    if (!_favoriteBusinessIds.remove(normalized)) {
      _favoriteBusinessIds.add(normalized);
    }
    notifyListeners();
    try {
      final preferences = await SharedPreferences.getInstance();
      final values = _favoriteBusinessIds.toList();
      final currentUserId = _userId;
      if (currentUserId != null) {
        await preferences.setStringList(
          _favoritesKeyFor(currentUserId),
          values,
        );
        await _remoteUpdater({'favoriteBusinessIds': values});
      }
    } catch (error) {
      debugPrint('[UserPreferencesProvider] favorites save failed: $error');
    }
  }

  static String _keyFor(String userId) => 'hexora.user.$userId.$_navigationKey';

  static String _collapsedKeyFor(String userId) =>
      'hexora.user.$userId.$_topNavCollapsedKey';

  static String _layoutKeyFor(String userId) =>
      'hexora.user.$userId.$_navigationLayoutKey';

  static String _headerPositionKeyFor(String userId) =>
      'hexora.user.$userId.$_globalHeaderPositionKey';

  static String _quoteKeyFor(String userId) =>
      'hexora.user.$userId.show_daily_quote';

  static String _favoritesKeyFor(String userId) =>
      'hexora.user.$userId.favorite_businesses';

  static String _modeToStorage(NavigationDisplayMode mode) => mode.name;

  static NavigationDisplayMode _modeFromStorage(String value) {
    return NavigationDisplayMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => defaultNavigationDisplayMode,
    );
  }

  static NavigationLayout _layoutFromStorage(String value) {
    return NavigationLayout.values.firstWhere(
      (layout) => layout.name == value,
      orElse: () => defaultNavigationLayout,
    );
  }

  static GlobalHeaderPosition _headerPositionFromStorage(String value) {
    return GlobalHeaderPosition.values.firstWhere(
      (position) => position.name == value,
      orElse: () => defaultGlobalHeaderPosition,
    );
  }
}
