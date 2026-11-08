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
    final preferences = UserPreferencesProvider();

    await preferences.bindUser('user-a');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.automatic,
    );
    await preferences.setNavigationDisplayMode(
      NavigationDisplayMode.iconsOnly,
    );

    await preferences.bindUser('user-b');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.automatic,
    );
    await preferences.setNavigationDisplayMode(
      NavigationDisplayMode.iconsAndText,
    );

    await preferences.bindUser('user-a');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );
  });

  test('legacy compact setting is migrated for the signed-in user', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_top_nav_compact_v2': true,
    });
    final preferences = UserPreferencesProvider();

    await preferences.bindUser('legacy-user');

    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.iconsOnly,
    );

    await preferences.bindUser('new-user');
    expect(
      preferences.navigationDisplayMode,
      NavigationDisplayMode.automatic,
    );
  });

  test('top navigation visibility persists independently per user', () async {
    final preferences = UserPreferencesProvider();

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
}
