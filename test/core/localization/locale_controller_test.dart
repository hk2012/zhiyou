import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhiyou_app/core/localization/locale_controller.dart';
import 'package:zhiyou_app/core/localization/locale_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts with system language when no preference is stored', () async {
    await AppLocaleStore.init();
    expect(AppLocaleStore.preference, AppLocalePreference.system);
  });

  test('persists a selected application language', () async {
    await AppLocaleStore.init();
    await AppLocaleStore.setPreference(AppLocalePreference.korean);

    final preferences = await SharedPreferences.getInstance();
    expect(AppLocaleStore.preference, AppLocalePreference.korean);
    expect(preferences.getString('app_locale'), 'ko');
  });
}
