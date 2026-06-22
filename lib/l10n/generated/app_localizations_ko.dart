// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '강호 낚시꾼';

  @override
  String get brandSmartDevices => '스마트 장비';

  @override
  String get brandAiDecision => 'AI 출조 의사결정';

  @override
  String get navHome => '홈';

  @override
  String get navExplore => '낚시터';

  @override
  String get navDevices => '장비';

  @override
  String get navMall => '용품';

  @override
  String get navProfile => '내 정보';

  @override
  String get navStartFishing => '낚시 시작';

  @override
  String get tooltipStartFishing => '이번 낚시 기록 시작';

  @override
  String get exploreTitle => '낚시터 선택';

  @override
  String get mallTitle => '출조 용품';

  @override
  String get mallSubtitle => '오늘 필요한 용품부터 확인';

  @override
  String get profileTitle => '내 정보';

  @override
  String get profileSubtitle => '자산 · 스마트 장비 · 주문';

  @override
  String get homeFunctions => '기능';

  @override
  String get homeCommonEntries => '빠른 실행';

  @override
  String get actionAll => '전체';

  @override
  String get homeFindSpot => '낚시터 찾기';

  @override
  String get homeRouteBooking => '경로 / 예약';

  @override
  String get homeStartFishing => '낚시 시작';

  @override
  String get homeFieldMode => '현장 모드';

  @override
  String get homeGear => '장비';

  @override
  String get homeChecklist => '체크리스트';

  @override
  String get homeDevices => '스마트 장비';

  @override
  String get homeControl => '제어';

  @override
  String get homeSupplies => '용품';

  @override
  String get homeByScene => '상황별';

  @override
  String get homeRecord => '기록';

  @override
  String get homeCatch => '조과';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '계정, 개인정보, 테마 및 장비 환경설정';

  @override
  String get settingsGeneral => '일반';

  @override
  String get settingsGeneralSubtitle => '캐시, 언어, 글꼴 및 장비 데이터';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsLanguageSubtitle => '시스템 언어를 따르거나 직접 선택';

  @override
  String get languageAndRegion => '언어 및 지역';

  @override
  String get languageSystem => '시스템 설정 사용';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageSystemDescription => '기기 언어를 우선 사용하며 지원하지 않으면 중국어로 표시합니다.';

  @override
  String get languageSelectionSaved => '언어 설정이 저장되었습니다';

  @override
  String get actionCancel => '취소';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionAddDevice => '장비 추가';

  @override
  String get deviceCenter => '장비 센터';

  @override
  String get deviceLoadFailed => '장비를 불러오지 못했습니다';

  @override
  String get deviceHealth => '장비 상태';

  @override
  String get deviceStable => '정상 작동';

  @override
  String devicePending(int count) {
    return '$count개 항목 확인 필요';
  }

  @override
  String get deviceOnline => '온라인';

  @override
  String get deviceStandby => '대기';

  @override
  String get deviceStrongSignal => '신호 강함';

  @override
  String get deviceWeakSignal => '신호 약함';

  @override
  String get deviceRealtimeApi => '실시간 API';

  @override
  String get deviceLocalDemo => '로컬 데모';

  @override
  String get deviceAll => '전체 장비';

  @override
  String get deviceAlertsOnly => '이상만 보기';

  @override
  String get deviceOnlineOnly => '온라인만 보기';

  @override
  String get deviceScenes => '자동화 장면';

  @override
  String get deviceTabStatus => '상태';

  @override
  String get deviceTabControl => '제어';

  @override
  String get deviceTabAutomation => '자동화';

  @override
  String get deviceTabMaintenance => '유지보수';

  @override
  String get localeChineseName => '중국어';

  @override
  String get localeEnglishName => '영어';

  @override
  String get localeKoreanName => '한국어';
}
