import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhiyou_app/core/localization/locale_preferences.dart';

void main() {
  test('supports system Chinese English and Korean selections', () {
    expect(AppLocalePreference.system.locale, isNull);
    expect(AppLocalePreference.chinese.locale, const Locale('zh'));
    expect(AppLocalePreference.english.locale, const Locale('en'));
    expect(AppLocalePreference.korean.locale, const Locale('ko'));
  });

  test('restores persisted values and falls back to system', () {
    expect(AppLocalePreference.fromStorage('ko'), AppLocalePreference.korean);
    expect(
      AppLocalePreference.fromStorage('unsupported'),
      AppLocalePreference.system,
    );
    expect(AppLocalePreference.fromStorage(null), AppLocalePreference.system);
  });

  test('normalizes unsupported device locales to Chinese', () {
    expect(
      resolveSupportedLocale(
        const Locale('ja'),
        preference: AppLocalePreference.system,
      ),
      const Locale('zh'),
    );
    expect(
      resolveSupportedLocale(
        const Locale('ko', 'KR'),
        preference: AppLocalePreference.system,
      ),
      const Locale('ko'),
    );
    expect(
      resolveSupportedLocale(
        const Locale('zh', 'TW'),
        preference: AppLocalePreference.english,
      ),
      const Locale('en'),
    );
  });
}
