// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '江湖钓客';

  @override
  String get brandSmartDevices => '智能设备';

  @override
  String get brandAiDecision => 'AI 出钓决策';

  @override
  String get navHome => '首页';

  @override
  String get navExplore => '钓场';

  @override
  String get navDevices => '设备';

  @override
  String get navMall => '补给';

  @override
  String get navProfile => '我的';

  @override
  String get navStartFishing => '开钓';

  @override
  String get tooltipStartFishing => '开始记录本次作钓';

  @override
  String get exploreTitle => '选钓点';

  @override
  String get mallTitle => '出钓补给';

  @override
  String get mallSubtitle => '先看今天缺什么';

  @override
  String get profileTitle => '我的';

  @override
  String get profileSubtitle => '用户资产 · 智能装备 · 订单服务';

  @override
  String get homeFunctions => '功能';

  @override
  String get homeCommonEntries => '常用入口';

  @override
  String get actionAll => '全部';

  @override
  String get homeFindSpot => '找钓点';

  @override
  String get homeRouteBooking => '路线 / 预约';

  @override
  String get homeStartFishing => '开钓';

  @override
  String get homeFieldMode => '现场模式';

  @override
  String get homeGear => '装备';

  @override
  String get homeChecklist => '清单';

  @override
  String get homeDevices => '设备';

  @override
  String get homeControl => '控制';

  @override
  String get homeSupplies => '补给';

  @override
  String get homeByScene => '按场景';

  @override
  String get homeRecord => '记录';

  @override
  String get homeCatch => '鱼获';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '账号、隐私、主题和设备偏好';

  @override
  String get settingsGeneral => '通用';

  @override
  String get settingsGeneralSubtitle => '缓存、语言、字体和设备数据';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageSubtitle => '跟随系统，也可手动切换';

  @override
  String get languageAndRegion => '语言与地区';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSystemDescription => '首次跟随设备语言，无法识别时使用简体中文。';

  @override
  String get languageSelectionSaved => '语言设置已保存';

  @override
  String get actionCancel => '取消';

  @override
  String get actionConfirm => '确认';

  @override
  String get actionRetry => '重试';

  @override
  String get actionBack => '返回';

  @override
  String get actionAddDevice => '新增设备';

  @override
  String get deviceCenter => '设备中心';

  @override
  String get deviceLoadFailed => '设备加载失败';

  @override
  String get deviceHealth => '设备健康';

  @override
  String get deviceStable => '运行稳定';

  @override
  String devicePending(int count) {
    return '$count 项待处理';
  }

  @override
  String get deviceOnline => '在线';

  @override
  String get deviceStandby => '待机';

  @override
  String get deviceStrongSignal => '信号强';

  @override
  String get deviceWeakSignal => '信号弱';

  @override
  String get deviceRealtimeApi => '实时 API';

  @override
  String get deviceLocalDemo => '本地演示';

  @override
  String get deviceAll => '全部设备';

  @override
  String get deviceAlertsOnly => '只看异常';

  @override
  String get deviceOnlineOnly => '只看在线';

  @override
  String get deviceScenes => '场景联动';

  @override
  String get deviceTabStatus => '状态';

  @override
  String get deviceTabControl => '控制';

  @override
  String get deviceTabAutomation => '自动化';

  @override
  String get deviceTabMaintenance => '维护';

  @override
  String get localeChineseName => '中文';

  @override
  String get localeEnglishName => '英文';

  @override
  String get localeKoreanName => '韩文';
}
