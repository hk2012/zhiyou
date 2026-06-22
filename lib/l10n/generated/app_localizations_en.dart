// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Jianghu Angler';

  @override
  String get brandSmartDevices => 'Smart Devices';

  @override
  String get brandAiDecision => 'AI Fishing Decisions';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Spots';

  @override
  String get navDevices => 'Devices';

  @override
  String get navMall => 'Supplies';

  @override
  String get navProfile => 'Profile';

  @override
  String get navStartFishing => 'Start';

  @override
  String get tooltipStartFishing => 'Start recording this fishing session';

  @override
  String get exploreTitle => 'Choose a fishing spot';

  @override
  String get mallTitle => 'Fishing supplies';

  @override
  String get mallSubtitle => 'See what you need today';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSubtitle => 'Assets · smart gear · orders';

  @override
  String get homeFunctions => 'Tools';

  @override
  String get homeCommonEntries => 'Quick actions';

  @override
  String get actionAll => 'All';

  @override
  String get homeFindSpot => 'Find a spot';

  @override
  String get homeRouteBooking => 'Route / booking';

  @override
  String get homeStartFishing => 'Start fishing';

  @override
  String get homeFieldMode => 'Field mode';

  @override
  String get homeGear => 'Gear';

  @override
  String get homeChecklist => 'Checklist';

  @override
  String get homeDevices => 'Devices';

  @override
  String get homeControl => 'Control';

  @override
  String get homeSupplies => 'Supplies';

  @override
  String get homeByScene => 'By scenario';

  @override
  String get homeRecord => 'Record';

  @override
  String get homeCatch => 'Catch';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Account, privacy, theme and device preferences';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsGeneralSubtitle => 'Cache, language, text and device data';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Follow the system or choose manually';

  @override
  String get languageAndRegion => 'Language & region';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSystemDescription =>
      'Uses the device language first and falls back to Simplified Chinese.';

  @override
  String get languageSelectionSaved => 'Language preference saved';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionBack => 'Back';

  @override
  String get actionAddDevice => 'Add device';

  @override
  String get deviceCenter => 'Device center';

  @override
  String get deviceLoadFailed => 'Unable to load devices';

  @override
  String get deviceHealth => 'Device health';

  @override
  String get deviceStable => 'Running normally';

  @override
  String devicePending(int count) {
    return '$count item(s) need attention';
  }

  @override
  String get deviceOnline => 'Online';

  @override
  String get deviceStandby => 'Standby';

  @override
  String get deviceStrongSignal => 'Strong signal';

  @override
  String get deviceWeakSignal => 'Weak signal';

  @override
  String get deviceRealtimeApi => 'Live API';

  @override
  String get deviceLocalDemo => 'Local demo';

  @override
  String get deviceAll => 'All devices';

  @override
  String get deviceAlertsOnly => 'Issues only';

  @override
  String get deviceOnlineOnly => 'Online only';

  @override
  String get deviceScenes => 'Automations';

  @override
  String get deviceTabStatus => 'Status';

  @override
  String get deviceTabControl => 'Control';

  @override
  String get deviceTabAutomation => 'Automation';

  @override
  String get deviceTabMaintenance => 'Maintenance';

  @override
  String get localeChineseName => 'Chinese';

  @override
  String get localeEnglishName => 'English';

  @override
  String get localeKoreanName => 'Korean';
}
