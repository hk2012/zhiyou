class SpotDetail {
  const SpotDetail({
    required this.spotId,
    required this.name,
    required this.headline,
    required this.summary,
    required this.score,
    required this.distanceLabel,
    required this.addressHint,
    required this.bestWindow,
    required this.waterTemperature,
    required this.depthLabel,
    required this.fishActivity,
    required this.riskLevel,
    required this.riskText,
    required this.parkingLabel,
    required this.routeMinutes,
    required this.targetFish,
    required this.facilities,
    required this.rules,
    required this.tactics,
    required this.safetyChecklist,
    required this.services,
    required this.forecast,
  });

  final int spotId;
  final String name;
  final String headline;
  final String summary;
  final int score;
  final String distanceLabel;
  final String addressHint;
  final String bestWindow;
  final String waterTemperature;
  final String depthLabel;
  final String fishActivity;
  final String riskLevel;
  final String riskText;
  final String parkingLabel;
  final int routeMinutes;
  final List<SpotFishTarget> targetFish;
  final List<SpotSectionItem> facilities;
  final List<SpotSectionItem> rules;
  final List<SpotSectionItem> tactics;
  final List<SpotSectionItem> safetyChecklist;
  final List<SpotSectionItem> services;
  final List<SpotSectionItem> forecast;

  factory SpotDetail.fromJson(Map<String, dynamic> json) {
    return SpotDetail(
      spotId: _asInt(json['spot_id']),
      name: json['name']?.toString() ?? '附近钓点',
      headline: json['headline']?.toString() ?? '今日适合先看安全和水情',
      summary: json['summary']?.toString() ?? '',
      score: _asInt(json['score']),
      distanceLabel: json['distance_label']?.toString() ?? '--',
      addressHint: json['address_hint']?.toString() ?? '',
      bestWindow: json['best_window']?.toString() ?? '--',
      waterTemperature: json['water_temperature']?.toString() ?? '--',
      depthLabel: json['depth_label']?.toString() ?? '--',
      fishActivity: json['fish_activity']?.toString() ?? '--',
      riskLevel: json['risk_level']?.toString() ?? '中',
      riskText: json['risk_text']?.toString() ?? '',
      parkingLabel: json['parking_label']?.toString() ?? '--',
      routeMinutes: _asInt(json['route_minutes']),
      targetFish: _asList(json['target_fish'], SpotFishTarget.fromJson),
      facilities: _asList(json['facilities'], SpotSectionItem.fromJson),
      rules: _asList(json['rules'], SpotSectionItem.fromJson),
      tactics: _asList(json['tactics'], SpotSectionItem.fromJson),
      safetyChecklist: _asList(
        json['safety_checklist'],
        SpotSectionItem.fromJson,
      ),
      services: _asList(json['services'], SpotSectionItem.fromJson),
      forecast: _asList(json['forecast'], SpotSectionItem.fromJson),
    );
  }
}

class SpotFishTarget {
  const SpotFishTarget({
    required this.fish,
    required this.activity,
    required this.method,
    required this.window,
  });

  final String fish;
  final int activity;
  final String method;
  final String window;

  factory SpotFishTarget.fromJson(Map<String, dynamic> json) {
    return SpotFishTarget(
      fish: json['fish']?.toString() ?? '',
      activity: _asInt(json['activity']),
      method: json['method']?.toString() ?? '',
      window: json['window']?.toString() ?? '',
    );
  }
}

class SpotSectionItem {
  const SpotSectionItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.accentKey,
  });

  final String title;
  final String subtitle;
  final String status;
  final String accentKey;

  factory SpotSectionItem.fromJson(Map<String, dynamic> json) {
    return SpotSectionItem(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? 'green',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<T> _asList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value.map((item) => fromJson(_asMap(item))).toList();
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
