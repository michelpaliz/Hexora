import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/models/user/user_preferences.dart';
import 'package:hexora/state/user_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('navigation mode is persisted independently for each user', () async {
    final preferences = _testPreferencesProvider();

    await preferences.bindUser('user-a');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
    await preferences.setNavigationDisplayMode(
      NavigationDisplayMode.automatic,
    );

    await preferences.bindUser('user-b');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
    await preferences.setNavigationDisplayMode(
      NavigationDisplayMode.iconsAndText,
    );

    await preferences.bindUser('user-a');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.automatic,
    );
  });

  test('legacy compact setting is migrated for the signed-in user', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_top_nav_compact_v2': true,
    });
    final preferences = _testPreferencesProvider();

    await preferences.bindUser('legacy-user');

    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );

    await preferences.bindUser('new-user');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
  });

  test('top navigation visibility persists independently per user', () async {
    final preferences = _testPreferencesProvider();

    await preferences.bindUser('user-a');
    await preferences.setNavigationDisplayMode(
      NavigationDisplayMode.iconsOnly,
    );
    await preferences.setTopNavCollapsed(true);

    await preferences.bindUser('user-b');
    expect(preferences.topNavCollapsed, isFalse);
    await preferences.setTopNavCollapsed(true);

    await preferences.bindUser('user-a');
    expect(preferences.topNavCollapsed, isTrue);
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );

    await preferences.setTopNavCollapsed(false);
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
  });

  test('navigation layout defaults to unified and persists per user', () async {
    final preferences = _testPreferencesProvider();

    await preferences.bindUser('user-a');
    expect(preferences.navigationLayout, NavigationLayout.unified);
    await preferences.setNavigationLayout(NavigationLayout.split);

    await preferences.bindUser('user-b');
    expect(preferences.navigationLayout, NavigationLayout.unified);

    await preferences.bindUser('user-a');
    expect(preferences.navigationLayout, NavigationLayout.split);
  });

  test('global header position defaults to bottom and persists per user',
      () async {
    final updates = <Map<String, dynamic>>[];
    final preferences = UserPreferencesProvider(
      remoteLoader: () async => <String, dynamic>{},
      remoteUpdater: (changes) async => updates.add(changes),
    );

    await preferences.bindUser('user-a');
    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.bottom);
    await preferences.setGlobalHeaderPosition(GlobalHeaderPosition.top);
    expect(updates.last, {'globalHeaderPosition': 'top'});

    await preferences.bindUser('user-b');
    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.bottom);

    await preferences.bindUser('user-a');
    expect(preferences.globalHeaderPosition, GlobalHeaderPosition.top);
  });
}

UserPreferencesProvider _testPreferencesProvider() {
  return UserPreferencesProvider(
    remoteLoader: () async => <String, dynamic>{},
    remoteUpdater: (_) async {},
  );
}
