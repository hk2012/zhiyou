import 'package:flutter/widgets.dart';

enum AppLocalePreference {
  system(null),
  chinese('zh'),
  english('en'),
  korean('ko');

  const AppLocalePreference(this.storageValue);

  final String? storageValue;

  Locale? get locale => storageValue == null ? null : Locale(storageValue!);

  static AppLocalePreference fromStorage(String? value) {
    return AppLocalePreference.values.firstWhere(
      (item) => item.storageValue == value,
      orElse: () => AppLocalePreference.system,
    );
  }
}

const supportedAppLocales = <Locale>[Locale('zh'), Locale('en'), Locale('ko')];

Locale resolveSupportedLocale(
  Locale deviceLocale, {
  required AppLocalePreference preference,
}) {
  final selected = preference.locale;
  if (selected != null) return selected;
  return supportedAppLocales.firstWhere(
    (locale) => locale.languageCode == deviceLocale.languageCode,
    orElse: () => const Locale('zh'),
  );
}
