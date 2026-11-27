import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hexora/state/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses a supported device language on the first visit', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = LocaleProvider(deviceLocale: const Locale('en', 'US'));
    addTearDown(provider.dispose);

    expect(provider.locale, const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('preferred_locale'), 'en');
  });

  test('falls back to the existing default for unsupported languages', () {
    SharedPreferences.setMockInitialValues({});
    final provider = LocaleProvider(deviceLocale: const Locale('fr'));
    addTearDown(provider.dispose);

    expect(provider.locale, LocaleProvider.defaultLocale);
  });

  test('a saved pre-auth selection overrides the device language', () async {
    SharedPreferences.setMockInitialValues({'preferred_locale': 'en'});
    final provider = LocaleProvider(deviceLocale: const Locale('es'));
    addTearDown(provider.dispose);

    await Future<void>.delayed(Duration.zero);
    expect(provider.locale, const Locale('en'));
  });
}
