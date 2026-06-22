import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'locale_preferences.dart';

class AppLocaleStore {
  AppLocaleStore._();

  static const _key = 'app_locale';
  static SharedPreferences? _preferences;
  static AppLocalePreference _preference = AppLocalePreference.system;

  static AppLocalePreference get preference => _preference;
  static Locale get effectiveLocale => resolveSupportedLocale(
    PlatformDispatcher.instance.locale,
    preference: _preference,
  );

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    _preference = AppLocalePreference.fromStorage(
      _preferences?.getString(_key),
    );
  }

  static Future<void> setPreference(AppLocalePreference preference) async {
    _preference = preference;
    if (preference.storageValue == null) {
      await _preferences?.remove(_key);
    } else {
      await _preferences?.setString(_key, preference.storageValue!);
    }
  }
}

class AppLocaleController extends Notifier<AppLocalePreference> {
  @override
  AppLocalePreference build() => AppLocaleStore.preference;

  Future<void> select(AppLocalePreference preference) async {
    state = preference;
    await AppLocaleStore.setPreference(preference);
  }
}

final appLocaleProvider =
    NotifierProvider<AppLocaleController, AppLocalePreference>(
      AppLocaleController.new,
    );
