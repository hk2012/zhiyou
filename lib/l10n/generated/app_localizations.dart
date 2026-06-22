import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'江湖钓客'**
  String get appName;

  /// No description provided for @brandSmartDevices.
  ///
  /// In zh, this message translates to:
  /// **'智能设备'**
  String get brandSmartDevices;

  /// No description provided for @brandAiDecision.
  ///
  /// In zh, this message translates to:
  /// **'AI 出钓决策'**
  String get brandAiDecision;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In zh, this message translates to:
  /// **'钓场'**
  String get navExplore;

  /// No description provided for @navDevices.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get navDevices;

  /// No description provided for @navMall.
  ///
  /// In zh, this message translates to:
  /// **'补给'**
  String get navMall;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navProfile;

  /// No description provided for @navStartFishing.
  ///
  /// In zh, this message translates to:
  /// **'开钓'**
  String get navStartFishing;

  /// No description provided for @tooltipStartFishing.
  ///
  /// In zh, this message translates to:
  /// **'开始记录本次作钓'**
  String get tooltipStartFishing;

  /// No description provided for @exploreTitle.
  ///
  /// In zh, this message translates to:
  /// **'选钓点'**
  String get exploreTitle;

  /// No description provided for @mallTitle.
  ///
  /// In zh, this message translates to:
  /// **'出钓补给'**
  String get mallTitle;

  /// No description provided for @mallSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'先看今天缺什么'**
  String get mallSubtitle;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'用户资产 · 智能装备 · 订单服务'**
  String get profileSubtitle;

  /// No description provided for @homeFunctions.
  ///
  /// In zh, this message translates to:
  /// **'功能'**
  String get homeFunctions;

  /// No description provided for @homeCommonEntries.
  ///
  /// In zh, this message translates to:
  /// **'常用入口'**
  String get homeCommonEntries;

  /// No description provided for @actionAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get actionAll;

  /// No description provided for @homeFindSpot.
  ///
  /// In zh, this message translates to:
  /// **'找钓点'**
  String get homeFindSpot;

  /// No description provided for @homeRouteBooking.
  ///
  /// In zh, this message translates to:
  /// **'路线 / 预约'**
  String get homeRouteBooking;

  /// No description provided for @homeStartFishing.
  ///
  /// In zh, this message translates to:
  /// **'开钓'**
  String get homeStartFishing;

  /// No description provided for @homeFieldMode.
  ///
  /// In zh, this message translates to:
  /// **'现场模式'**
  String get homeFieldMode;

  /// No description provided for @homeGear.
  ///
  /// In zh, this message translates to:
  /// **'装备'**
  String get homeGear;

  /// No description provided for @homeChecklist.
  ///
  /// In zh, this message translates to:
  /// **'清单'**
  String get homeChecklist;

  /// No description provided for @homeDevices.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get homeDevices;

  /// No description provided for @homeControl.
  ///
  /// In zh, this message translates to:
  /// **'控制'**
  String get homeControl;

  /// No description provided for @homeSupplies.
  ///
  /// In zh, this message translates to:
  /// **'补给'**
  String get homeSupplies;

  /// No description provided for @homeByScene.
  ///
  /// In zh, this message translates to:
  /// **'按场景'**
  String get homeByScene;

  /// No description provided for @homeRecord.
  ///
  /// In zh, this message translates to:
  /// **'记录'**
  String get homeRecord;

  /// No description provided for @homeCatch.
  ///
  /// In zh, this message translates to:
  /// **'鱼获'**
  String get homeCatch;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'账号、隐私、主题和设备偏好'**
  String get settingsSubtitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get settingsGeneral;

  /// No description provided for @settingsGeneralSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'缓存、语言、字体和设备数据'**
  String get settingsGeneralSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统，也可手动切换'**
  String get settingsLanguageSubtitle;

  /// No description provided for @languageAndRegion.
  ///
  /// In zh, this message translates to:
  /// **'语言与地区'**
  String get languageAndRegion;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKorean.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageSystemDescription.
  ///
  /// In zh, this message translates to:
  /// **'首次跟随设备语言，无法识别时使用简体中文。'**
  String get languageSystemDescription;

  /// No description provided for @languageSelectionSaved.
  ///
  /// In zh, this message translates to:
  /// **'语言设置已保存'**
  String get languageSelectionSaved;

  /// No description provided for @actionCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get actionConfirm;

  /// No description provided for @actionRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get actionBack;

  /// No description provided for @actionAddDevice.
  ///
  /// In zh, this message translates to:
  /// **'新增设备'**
  String get actionAddDevice;

  /// No description provided for @deviceCenter.
  ///
  /// In zh, this message translates to:
  /// **'设备中心'**
  String get deviceCenter;

  /// No description provided for @deviceLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'设备加载失败'**
  String get deviceLoadFailed;

  /// No description provided for @deviceHealth.
  ///
  /// In zh, this message translates to:
  /// **'设备健康'**
  String get deviceHealth;

  /// No description provided for @deviceStable.
  ///
  /// In zh, this message translates to:
  /// **'运行稳定'**
  String get deviceStable;

  /// No description provided for @devicePending.
  ///
  /// In zh, this message translates to:
  /// **'{count} 项待处理'**
  String devicePending(int count);

  /// No description provided for @deviceOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get deviceOnline;

  /// No description provided for @deviceStandby.
  ///
  /// In zh, this message translates to:
  /// **'待机'**
  String get deviceStandby;

  /// No description provided for @deviceStrongSignal.
  ///
  /// In zh, this message translates to:
  /// **'信号强'**
  String get deviceStrongSignal;

  /// No description provided for @deviceWeakSignal.
  ///
  /// In zh, this message translates to:
  /// **'信号弱'**
  String get deviceWeakSignal;

  /// No description provided for @deviceRealtimeApi.
  ///
  /// In zh, this message translates to:
  /// **'实时 API'**
  String get deviceRealtimeApi;

  /// No description provided for @deviceLocalDemo.
  ///
  /// In zh, this message translates to:
  /// **'本地演示'**
  String get deviceLocalDemo;

  /// No description provided for @deviceAll.
  ///
  /// In zh, this message translates to:
  /// **'全部设备'**
  String get deviceAll;

  /// No description provided for @deviceAlertsOnly.
  ///
  /// In zh, this message translates to:
  /// **'只看异常'**
  String get deviceAlertsOnly;

  /// No description provided for @deviceOnlineOnly.
  ///
  /// In zh, this message translates to:
  /// **'只看在线'**
  String get deviceOnlineOnly;

  /// No description provided for @deviceScenes.
  ///
  /// In zh, this message translates to:
  /// **'场景联动'**
  String get deviceScenes;

  /// No description provided for @deviceTabStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get deviceTabStatus;

  /// No description provided for @deviceTabControl.
  ///
  /// In zh, this message translates to:
  /// **'控制'**
  String get deviceTabControl;

  /// No description provided for @deviceTabAutomation.
  ///
  /// In zh, this message translates to:
  /// **'自动化'**
  String get deviceTabAutomation;

  /// No description provided for @deviceTabMaintenance.
  ///
  /// In zh, this message translates to:
  /// **'维护'**
  String get deviceTabMaintenance;

  /// No description provided for @localeChineseName.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get localeChineseName;

  /// No description provided for @localeEnglishName.
  ///
  /// In zh, this message translates to:
  /// **'英文'**
  String get localeEnglishName;

  /// No description provided for @localeKoreanName.
  ///
  /// In zh, this message translates to:
  /// **'韩文'**
  String get localeKoreanName;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
