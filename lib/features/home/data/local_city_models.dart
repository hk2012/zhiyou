import 'home_recommendation_models.dart';

class LocalTrialCity {
  const LocalTrialCity({
    required this.code,
    required this.name,
    required this.province,
    required this.adcode,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.role,
    required this.strategy,
    required this.complianceSummary,
    required this.districts,
  });

  final String code;
  final String name;
  final String province;
  final String adcode;
  final double centerLatitude;
  final double centerLongitude;
  final String role;
  final String strategy;
  final String complianceSummary;
  final List<String> districts;

  factory LocalTrialCity.fromJson(Map<String, dynamic> json) {
    return LocalTrialCity(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      province: json['province']?.toString() ?? '江苏省',
      adcode: json['adcode']?.toString() ?? '',
      centerLatitude: _asDouble(json['center_latitude']),
      centerLongitude: _asDouble(json['center_longitude']),
      role: json['role']?.toString() ?? '',
      strategy: json['strategy']?.toString() ?? '',
      complianceSummary: json['compliance_summary']?.toString() ?? '',
      districts: _asStringList(json['districts']),
    );
  }
}

class LocalWeatherSnapshot {
  const LocalWeatherSnapshot({
    required this.condition,
    required this.temperatureC,
    required this.windDirection,
    required this.windLevel,
    required this.pressureTrend,
    required this.waterClarity,
    required this.season,
    required this.summary,
    required this.source,
    required this.updatedAt,
    this.waterTemperatureC,
    this.pressureHpa,
    this.tideStage,
  });

  final String condition;
  final double temperatureC;
  final double? waterTemperatureC;
  final String windDirection;
  final int windLevel;
  final double? pressureHpa;
  final String pressureTrend;
  final String waterClarity;
  final String season;
  final String? tideStage;
  final String summary;
  final String source;
  final DateTime? updatedAt;

  String get weatherLabel => '$condition ${temperatureC.round()}°C';
  String get waterTempLabel {
    final value = waterTemperatureC;
    if (value == null) return '水温 --';
    return '水温 ${value.toStringAsFixed(1)}°C';
  }

  Map<String, dynamic> toHomeWeatherJson() {
    return {
      'condition': condition,
      'temperature_c': temperatureC,
      if (waterTemperatureC != null) 'water_temperature_c': waterTemperatureC,
      'wind_direction': windDirection,
      'wind_level': windLevel,
      if (pressureHpa != null) 'pressure_hpa': pressureHpa,
      'pressure_trend': pressureTrend,
      'water_clarity': waterClarity,
      'season': season,
      if (tideStage != null && tideStage!.isNotEmpty) 'tide_stage': tideStage,
      'hour': DateTime.now().hour,
    };
  }

  factory LocalWeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return LocalWeatherSnapshot(
      condition: json['condition']?.toString() ?? '多云',
      temperatureC: _asDouble(json['temperature_c']),
      waterTemperatureC: _asNullableDouble(json['water_temperature_c']),
      windDirection: json['wind_direction']?.toString() ?? '微风',
      windLevel: _asInt(json['wind_level']) ?? 2,
      pressureHpa: _asNullableDouble(json['pressure_hpa']),
      pressureTrend: json['pressure_trend']?.toString() ?? 'stable',
      waterClarity: json['water_clarity']?.toString() ?? '微浑',
      season: json['season']?.toString() ?? '夏季',
      tideStage: json['tide_stage']?.toString(),
      summary: json['summary']?.toString() ?? '',
      source: json['source']?.toString() ?? 'fallback',
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }
}

class LocalRouteSummary {
  const LocalRouteSummary({
    required this.distanceKm,
    required this.durationMin,
    required this.distanceLabel,
    required this.durationLabel,
    required this.source,
  });

  final double distanceKm;
  final int durationMin;
  final String distanceLabel;
  final String durationLabel;
  final String source;

  String get displayLabel => '$distanceLabel · $durationLabel';

  factory LocalRouteSummary.fromJson(Map<String, dynamic> json) {
    return LocalRouteSummary(
      distanceKm: _asDouble(json['distance_km']),
      durationMin: _asInt(json['duration_min']) ?? 0,
      distanceLabel: json['distance_label']?.toString() ?? '',
      durationLabel: json['duration_label']?.toString() ?? '',
      source: json['source']?.toString() ?? 'fallback',
    );
  }
}

class LocalComplianceNotice {
  const LocalComplianceNotice({
    required this.status,
    required this.label,
    required this.summary,
    required this.sourceName,
    required this.sourceUrl,
    required this.updatedAt,
  });

  final String status;
  final String label;
  final String summary;
  final String sourceName;
  final String sourceUrl;
  final String updatedAt;

  factory LocalComplianceNotice.fromJson(Map<String, dynamic> json) {
    return LocalComplianceNotice(
      status: json['status']?.toString() ?? 'unknown',
      label: json['label']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      sourceName: json['source_name']?.toString() ?? '',
      sourceUrl: json['source_url']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

class VenueVerificationItem {
  const VenueVerificationItem({
    required this.title,
    required this.status,
    required this.evidence,
    required this.nextStep,
  });

  final String title;
  final String status;
  final String evidence;
  final String nextStep;

  factory VenueVerificationItem.fromJson(Map<String, dynamic> json) {
    return VenueVerificationItem(
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      evidence: json['evidence']?.toString() ?? '',
      nextStep: json['next_step']?.toString() ?? '',
    );
  }
}

class VenueVerification {
  const VenueVerification({
    required this.status,
    required this.label,
    required this.summary,
    required this.verifiedBy,
    required this.lastVerifiedAt,
    required this.items,
  });

  final String status;
  final String label;
  final String summary;
  final String verifiedBy;
  final String lastVerifiedAt;
  final List<VenueVerificationItem> items;

  factory VenueVerification.fromJson(Map<String, dynamic> json) {
    return VenueVerification(
      status: json['status']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      verifiedBy: json['verified_by']?.toString() ?? '',
      lastVerifiedAt: json['last_verified_at']?.toString() ?? '',
      items: _asList(json['items'], VenueVerificationItem.fromJson),
    );
  }
}

class VenueVerificationQueueEntry {
  const VenueVerificationQueueEntry({
    required this.queueId,
    required this.venueId,
    required this.cityCode,
    required this.cityName,
    required this.title,
    required this.district,
    required this.priority,
    required this.status,
    required this.reason,
    required this.requestedBy,
    required this.nextStep,
    required this.routeLabel,
    required this.complianceLabel,
    required this.verificationLabel,
    required this.createdAt,
  });

  final String queueId;
  final String venueId;
  final String cityCode;
  final String cityName;
  final String title;
  final String district;
  final String priority;
  final String status;
  final String reason;
  final String requestedBy;
  final String nextStep;
  final String routeLabel;
  final String complianceLabel;
  final String verificationLabel;
  final DateTime? createdAt;

  String get priorityLabel {
    return switch (priority) {
      'high' => '高优先级',
      'medium' => '中优先级',
      _ => '普通优先级',
    };
  }

  factory VenueVerificationQueueEntry.fromJson(Map<String, dynamic> json) {
    return VenueVerificationQueueEntry(
      queueId: json['queue_id']?.toString() ?? '',
      venueId: json['venue_id']?.toString() ?? '',
      cityCode: json['city_code']?.toString() ?? '',
      cityName: json['city_name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      requestedBy: json['requested_by']?.toString() ?? '',
      nextStep: json['next_step']?.toString() ?? '',
      routeLabel: json['route_label']?.toString() ?? '',
      complianceLabel: json['compliance_label']?.toString() ?? '',
      verificationLabel: json['verification_label']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class LocalFishingVenue {
  const LocalFishingVenue({
    required this.venueId,
    required this.cityCode,
    required this.title,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.rating,
    required this.priceLabel,
    required this.fishSpecies,
    required this.methods,
    required this.tags,
    required this.todayReason,
    required this.bookable,
    required this.dataSource,
    required this.route,
    required this.compliance,
    required this.verification,
    required this.navigationUrls,
    this.memberPriceLabel,
  });

  final String venueId;
  final String cityCode;
  final String title;
  final String district;
  final double latitude;
  final double longitude;
  final double rating;
  final String priceLabel;
  final String? memberPriceLabel;
  final List<String> fishSpecies;
  final List<String> methods;
  final List<String> tags;
  final String todayReason;
  final bool bookable;
  final String dataSource;
  final LocalRouteSummary route;
  final LocalComplianceNotice compliance;
  final VenueVerification verification;
  final Map<String, String> navigationUrls;

  String get priceSummary {
    final member = memberPriceLabel;
    if (member == null || member.isEmpty) return priceLabel;
    return '$priceLabel · $member';
  }

  factory LocalFishingVenue.fromJson(Map<String, dynamic> json) {
    return LocalFishingVenue(
      venueId: json['venue_id']?.toString() ?? '',
      cityCode: json['city_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      rating: _asDouble(json['rating']),
      priceLabel: json['price_label']?.toString() ?? '',
      memberPriceLabel: json['member_price_label']?.toString(),
      fishSpecies: _asStringList(json['fish_species']),
      methods: _asStringList(json['methods']),
      tags: _asStringList(json['tags']),
      todayReason: json['today_reason']?.toString() ?? '',
      bookable: json['bookable'] != false,
      dataSource: json['data_source']?.toString() ?? '',
      route: LocalRouteSummary.fromJson(_asMap(json['route'])),
      compliance: LocalComplianceNotice.fromJson(_asMap(json['compliance'])),
      verification: VenueVerification.fromJson(_asMap(json['verification'])),
      navigationUrls: _asStringMap(json['navigation_urls']),
    );
  }
}

class LocalCityContext {
  const LocalCityContext({
    required this.city,
    required this.weather,
    required this.venues,
    required this.complianceNotices,
    required this.nextAction,
  });

  final LocalTrialCity city;
  final LocalWeatherSnapshot weather;
  final List<LocalFishingVenue> venues;
  final List<LocalComplianceNotice> complianceNotices;
  final String nextAction;

  LocalFishingVenue? get primaryVenue => venues.isEmpty ? null : venues.first;

  HomeLocation get recommendationLocation {
    final venue = primaryVenue;
    if (venue == null) {
      return HomeLocation(
        name: '${city.name} · 试点城市',
        latitude: city.centerLatitude,
        longitude: city.centerLongitude,
        source: 'trial_city',
        statusMessage: nextAction,
      );
    }
    return HomeLocation(
      name: '${city.name} · ${venue.title}',
      latitude: venue.latitude,
      longitude: venue.longitude,
      source: 'trial_city',
      statusMessage: nextAction,
    );
  }

  factory LocalCityContext.fromJson(Map<String, dynamic> json) {
    return LocalCityContext(
      city: LocalTrialCity.fromJson(_asMap(json['city'])),
      weather: LocalWeatherSnapshot.fromJson(_asMap(json['weather'])),
      venues: _asList(json['venues'], LocalFishingVenue.fromJson),
      complianceNotices: _asList(
        json['compliance_notices'],
        LocalComplianceNotice.fromJson,
      ),
      nextAction: json['next_action']?.toString() ?? '',
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}

Map<String, String> _asStringMap(dynamic value) {
  final map = _asMap(value);
  return map.map((key, value) => MapEntry(key, value.toString()));
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
