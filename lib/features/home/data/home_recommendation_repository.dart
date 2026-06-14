import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'home_location_reader.dart';
import 'home_recommendation_models.dart';

final homeRecommendationRepositoryProvider =
    Provider<HomeRecommendationRepository>((ref) {
      return HomeRecommendationRepository(
        DioClient.instance,
        HomeLocationService(),
      );
    });

class HomeRecommendationRepository {
  HomeRecommendationRepository(this._dio, this._locationService);

  final Dio _dio;
  final HomeLocationService _locationService;

  Future<HomeLocation> resolveLocation({required bool requestPrecise}) {
    return _locationService.resolveLocation(requestPrecise: requestPrecise);
  }

  Future<List<HomeCardPreference>> fetchCardPreferences() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/home/card-preferences',
      queryParameters: {'user_id': 1},
    );
    final cards = response.data?['cards'];
    if (cards is! List) return const [];
    return cards
        .map((item) => HomeCardPreference.fromJson(_asResponseMap(item)))
        .toList();
  }

  Future<List<HomeCardPreference>> saveCardPreferences(
    List<HomeCardPreference> preferences,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/home/card-preferences',
      data: {
        'user_id': 1,
        'cards': [for (final item in preferences) item.toJson()],
      },
    );
    final cards = response.data?['cards'];
    if (cards is! List) return preferences;
    return cards
        .map((item) => HomeCardPreference.fromJson(_asResponseMap(item)))
        .toList();
  }

  Future<HomeRecommendationSummary> fetchSummary({
    required List<String> enabledCardIds,
    required HomeLocation location,
    List<HomeExpertObservation> expertObservations = const [],
    bool recalibrate = false,
  }) async {
    final path = recalibrate && expertObservations.isNotEmpty
        ? '/api/v1/home/recalibrate'
        : '/api/v1/home/summary';
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {
        'user_id': 1,
        'location_name': location.name,
        if (location.latitude != null) 'latitude': location.latitude,
        if (location.longitude != null) 'longitude': location.longitude,
        'enabled_cards': enabledCardIds,
        if (expertObservations.isNotEmpty)
          'expert_observations': [
            for (final observation in expertObservations) observation.toJson(),
          ],
        'weather': {
          'hour': DateTime.now().hour,
          // 天气数据后面会接真实供应商；现在先让后端使用可解释的默认水情。
          'condition': '多云',
          'season': '夏季',
          'water_clarity': '微浑',
        },
      },
    );

    return HomeRecommendationSummary.fromJson(response.data ?? {});
  }

  Future<FishingAiAnalysis> analyzeFishing({
    required String locationName,
    required String target,
    required String weather,
    required String waterTemperature,
    required String depth,
    required String bestTime,
    required String spotHint,
    required String gear,
    required int baselineScore,
    required int adjustedScore,
    required String localHeadline,
    required String localStrategy,
    required List<Map<String, String>> observations,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/ai/fishing-analysis',
      data: {
        'location_name': locationName,
        'target': target,
        'weather': weather,
        'water_temperature': waterTemperature,
        'depth': depth,
        'best_time': bestTime,
        'spot_hint': spotHint,
        'gear': gear,
        'baseline_score': baselineScore,
        'adjusted_score': adjustedScore,
        'local_headline': localHeadline,
        'local_strategy': localStrategy,
        'observations': observations,
      },
    );
    return FishingAiAnalysis.fromJson(response.data ?? {});
  }

  Future<CatchRecordResult> recordCatch({
    required HomeLocation location,
    required String fish,
    required String method,
    required int probability,
    required String praiseTitle,
    required String shareCopy,
    required String visibility,
    double? lengthCm,
    double? weightJin,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'user_id': 1,
      'location_name': location.name,
      if (location.latitude != null) 'latitude': location.latitude,
      if (location.longitude != null) 'longitude': location.longitude,
      'fish': fish,
      'method': method,
      'probability_at_time': probability,
      'is_low_probability': probability <= 25,
      'praise_title': praiseTitle,
      'share_copy': shareCopy,
      'visibility': visibility,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    if (lengthCm != null) {
      data['length_cm'] = lengthCm;
    }
    if (weightJin != null) {
      data['weight_kg'] = weightJin * 0.5;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/home/catch-records',
      data: data,
    );
    return CatchRecordResult.fromJson(response.data ?? {});
  }
}

Map<String, dynamic> _asResponseMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

class HomeLocationService {
  static const fallbackLocation = HomeLocation(
    name: '千岛湖 · 东南湖区',
    latitude: 29.594,
    longitude: 119.054,
    statusMessage: '未获取到真实定位，使用默认钓点',
  );

  HomeLocation? _cachedDeviceLocation;

  Future<HomeLocation> resolveLocation({required bool requestPrecise}) async {
    if (!requestPrecise) return _cachedDeviceLocation ?? fallbackLocation;

    try {
      final location = await readDeviceLocation();
      if (location != null) {
        _cachedDeviceLocation = location;
        return location;
      }
      return _cachedDeviceLocation ?? fallbackLocation;
    } catch (_) {
      return _cachedDeviceLocation ?? fallbackLocation;
    }
  }
}
