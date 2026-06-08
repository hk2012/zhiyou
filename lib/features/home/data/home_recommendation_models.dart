class HomeLocation {
  const HomeLocation({
    required this.name,
    this.latitude,
    this.longitude,
    this.source = 'fallback',
    this.statusMessage = '使用默认钓点生成推荐',
    this.accuracyMeters,
  });

  final String name;
  final double? latitude;
  final double? longitude;
  final String source;
  final String statusMessage;
  final double? accuracyMeters;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isDeviceLocation => source == 'device';
}

class HomeExpertObservation {
  const HomeExpertObservation({
    required this.key,
    required this.label,
    required this.value,
    this.weight = 1,
  });

  final String key;
  final String label;
  final String value;
  final double weight;

  Map<String, dynamic> toJson() {
    return {'key': key, 'label': label, 'value': value, 'weight': weight};
  }
}

class HomeRecommendationSummary {
  const HomeRecommendationSummary({
    required this.recommendationId,
    required this.locationName,
    required this.generatedAt,
    required this.visibleCardIds,
    required this.conclusion,
    required this.fishTargets,
    required this.methodMatches,
    required this.avoidAdvices,
    required this.lowChallenge,
    required this.expertAdjustments,
    required this.recentMethods,
    required this.seasonalWaterAdvices,
    required this.safetyRisks,
    required this.dataSources,
    required this.latestCatch,
  });

  final int? recommendationId;
  final String locationName;
  final DateTime? generatedAt;
  final List<String> visibleCardIds;
  final PlayConclusion conclusion;
  final List<FishTarget> fishTargets;
  final List<MethodFishMatch> methodMatches;
  final List<AvoidAdvice> avoidAdvices;
  final LowProbabilityChallenge lowChallenge;
  final List<ExpertAdjustment> expertAdjustments;
  final List<RecentMethodInsight> recentMethods;
  final List<SeasonalWaterAdvice> seasonalWaterAdvices;
  final List<SafetyRiskAdvice> safetyRisks;
  final List<DataSourceHealth> dataSources;
  final CatchRecordResult? latestCatch;

  factory HomeRecommendationSummary.fromJson(Map<String, dynamic> json) {
    return HomeRecommendationSummary(
      recommendationId: _asInt(json['recommendation_id']),
      locationName: json['location_name']?.toString() ?? '附近水域',
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
      visibleCardIds: _asStringList(json['visible_cards']),
      conclusion: PlayConclusion.fromJson(_asMap(json['conclusion'])),
      fishTargets: _asList(json['fish_targets'], FishTarget.fromJson),
      methodMatches: _asList(json['method_matches'], MethodFishMatch.fromJson),
      avoidAdvices: _asList(json['avoid_advices'], AvoidAdvice.fromJson),
      lowChallenge: LowProbabilityChallenge.fromJson(
        _asMap(json['low_challenge']),
      ),
      expertAdjustments: _asList(
        json['expert_adjustments'],
        ExpertAdjustment.fromJson,
      ),
      recentMethods: _asList(
        json['recent_methods'],
        RecentMethodInsight.fromJson,
      ),
      seasonalWaterAdvices: _asList(
        json['seasonal_water_advices'],
        SeasonalWaterAdvice.fromJson,
      ),
      safetyRisks: _asList(json['safety_risks'], SafetyRiskAdvice.fromJson),
      dataSources: _asList(json['data_sources'], DataSourceHealth.fromJson),
      latestCatch: _asOptionalMap(
        json['latest_catch'],
        CatchRecordResult.fromJson,
      ),
    );
  }
}

class HomeCardPreference {
  const HomeCardPreference({
    required this.cardId,
    required this.enabled,
    required this.sortOrder,
  });

  final String cardId;
  final bool enabled;
  final int sortOrder;

  factory HomeCardPreference.fromJson(Map<String, dynamic> json) {
    return HomeCardPreference(
      cardId: json['card_id']?.toString() ?? '',
      enabled: json['enabled'] == true,
      sortOrder: _asInt(json['sort_order']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'card_id': cardId, 'enabled': enabled, 'sort_order': sortOrder};
  }
}

class CatchRecordResult {
  const CatchRecordResult({
    required this.id,
    required this.fish,
    required this.method,
    required this.praiseTitle,
    required this.shareCopy,
    required this.createdAt,
    this.lengthCm,
    this.weightKg,
    this.probabilityAtTime,
    this.isLowProbability = false,
  });

  final int id;
  final String fish;
  final String method;
  final String praiseTitle;
  final String shareCopy;
  final DateTime? createdAt;
  final double? lengthCm;
  final double? weightKg;
  final int? probabilityAtTime;
  final bool isLowProbability;

  factory CatchRecordResult.fromJson(Map<String, dynamic> json) {
    return CatchRecordResult(
      id: _asInt(json['id']) ?? 0,
      fish: json['fish']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      praiseTitle: json['praise_title']?.toString() ?? '',
      shareCopy: json['share_copy']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      lengthCm: _asNullableDouble(json['length_cm']),
      weightKg: _asNullableDouble(json['weight_kg']),
      probabilityAtTime: _asInt(json['probability_at_time']),
      isLowProbability: json['is_low_probability'] == true,
    );
  }
}

class PlayConclusion {
  const PlayConclusion({
    required this.title,
    required this.score,
    required this.summary,
    required this.bestTime,
    required this.spotHint,
    required this.rigHint,
    required this.reasons,
    required this.missingPoints,
  });

  final String title;
  final int score;
  final String summary;
  final String bestTime;
  final String spotHint;
  final String rigHint;
  final List<String> reasons;
  final List<ScoreLoss> missingPoints;

  factory PlayConclusion.fromJson(Map<String, dynamic> json) {
    return PlayConclusion(
      title: json['title']?.toString() ?? '今日推荐',
      score: _asInt(json['score']) ?? 0,
      summary: json['summary']?.toString() ?? '',
      bestTime: json['best_time']?.toString() ?? '',
      spotHint: json['spot_hint']?.toString() ?? '',
      rigHint: json['rig_hint']?.toString() ?? '',
      reasons: _asStringList(json['reasons']),
      missingPoints: _asList(json['missing_points'], ScoreLoss.fromJson),
    );
  }
}

class ScoreLoss {
  const ScoreLoss({
    required this.title,
    required this.points,
    required this.advice,
  });

  final String title;
  final int points;
  final String advice;

  factory ScoreLoss.fromJson(Map<String, dynamic> json) {
    return ScoreLoss(
      title: json['title']?.toString() ?? '',
      points: _asInt(json['points']) ?? 0,
      advice: json['advice']?.toString() ?? '',
    );
  }
}

class FishTarget {
  const FishTarget({
    required this.fish,
    required this.score,
    required this.probabilityLabel,
    required this.method,
    required this.reason,
  });

  final String fish;
  final int score;
  final String probabilityLabel;
  final String method;
  final String reason;

  factory FishTarget.fromJson(Map<String, dynamic> json) {
    return FishTarget(
      fish: json['fish']?.toString() ?? '',
      score: _asInt(json['score']) ?? 0,
      probabilityLabel: json['probability_label']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }
}

class MethodFishMatch {
  const MethodFishMatch({
    required this.method,
    required this.fish,
    required this.chance,
    required this.tactic,
    required this.conclusion,
  });

  final String method;
  final String fish;
  final String chance;
  final String tactic;
  final String conclusion;

  factory MethodFishMatch.fromJson(Map<String, dynamic> json) {
    return MethodFishMatch(
      method: json['method']?.toString() ?? '',
      fish: json['fish']?.toString() ?? '',
      chance: json['chance']?.toString() ?? '',
      tactic: json['tactic']?.toString() ?? '',
      conclusion: json['conclusion']?.toString() ?? '',
    );
  }
}

class AvoidAdvice {
  const AvoidAdvice({
    required this.title,
    required this.reason,
    required this.alternative,
  });

  final String title;
  final String reason;
  final String alternative;

  factory AvoidAdvice.fromJson(Map<String, dynamic> json) {
    return AvoidAdvice(
      title: json['title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      alternative: json['alternative']?.toString() ?? '',
    );
  }
}

class LowProbabilityChallenge {
  const LowProbabilityChallenge({
    required this.fish,
    required this.probability,
    required this.praiseTitle,
    required this.shareCopy,
  });

  final String fish;
  final int probability;
  final String praiseTitle;
  final String shareCopy;

  factory LowProbabilityChallenge.fromJson(Map<String, dynamic> json) {
    return LowProbabilityChallenge(
      fish: json['fish']?.toString() ?? '',
      probability: _asInt(json['probability']) ?? 0,
      praiseTitle: json['praise_title']?.toString() ?? '',
      shareCopy: json['share_copy']?.toString() ?? '',
    );
  }
}

class ExpertAdjustment {
  const ExpertAdjustment({
    required this.label,
    required this.effect,
    required this.advice,
  });

  final String label;
  final String effect;
  final String advice;

  factory ExpertAdjustment.fromJson(Map<String, dynamic> json) {
    return ExpertAdjustment(
      label: json['label']?.toString() ?? '',
      effect: json['effect']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
    );
  }
}

class RecentMethodInsight {
  const RecentMethodInsight({
    required this.methodLabel,
    required this.sharePercent,
    required this.sampleSize,
  });

  final String methodLabel;
  final double sharePercent;
  final int sampleSize;

  factory RecentMethodInsight.fromJson(Map<String, dynamic> json) {
    return RecentMethodInsight(
      methodLabel: json['method_label']?.toString() ?? '',
      sharePercent: _asDouble(json['share_percent']),
      sampleSize: _asInt(json['sample_size']) ?? 0,
    );
  }
}

class SeasonalWaterAdvice {
  const SeasonalWaterAdvice({
    required this.title,
    required this.timeWindow,
    required this.advice,
  });

  final String title;
  final String timeWindow;
  final String advice;

  factory SeasonalWaterAdvice.fromJson(Map<String, dynamic> json) {
    return SeasonalWaterAdvice(
      title: json['title']?.toString() ?? '',
      timeWindow: json['time_window']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
    );
  }
}

class SafetyRiskAdvice {
  const SafetyRiskAdvice({
    required this.title,
    required this.level,
    required this.advice,
  });

  final String title;
  final String level;
  final String advice;

  factory SafetyRiskAdvice.fromJson(Map<String, dynamic> json) {
    return SafetyRiskAdvice(
      title: json['title']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      advice: json['advice']?.toString() ?? '',
    );
  }
}

class DataSourceHealth {
  const DataSourceHealth({
    required this.sourceName,
    required this.confidenceLabel,
    required this.payload,
  });

  final String sourceName;
  final String confidenceLabel;
  final Map<String, dynamic> payload;

  factory DataSourceHealth.fromJson(Map<String, dynamic> json) {
    return DataSourceHealth(
      sourceName: json['source_name']?.toString() ?? '',
      confidenceLabel: json['confidence_label']?.toString() ?? '',
      payload: _asMap(json['payload']),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

List<String> _asStringList(dynamic value) {
  if (value is List) return value.map((item) => item.toString()).toList();
  return const [];
}

List<T> _asList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value is! List) return const [];
  return value.map((item) => fromJson(_asMap(item))).toList();
}

T? _asOptionalMap<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) fromJson,
) {
  if (value == null) return null;
  final map = _asMap(value);
  if (map.isEmpty) return null;
  return fromJson(map);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
