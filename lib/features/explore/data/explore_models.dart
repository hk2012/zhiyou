class ExploreSummary {
  const ExploreSummary({
    required this.layers,
    required this.signals,
    required this.map,
    required this.featuredSpot,
    required this.ecosystemItems,
  });

  final List<ExploreLayer> layers;
  final List<ExploreSignal> signals;
  final ExploreMapData map;
  final ExploreFeaturedSpot featuredSpot;
  final List<ExploreEcosystemItem> ecosystemItems;

  factory ExploreSummary.fromJson(Map<String, dynamic> json) {
    return ExploreSummary(
      layers: _asList(json['layers'], ExploreLayer.fromJson),
      signals: _asList(json['signals'], ExploreSignal.fromJson),
      map: ExploreMapData.fromJson(_asMap(json['map'])),
      featuredSpot: ExploreFeaturedSpot.fromJson(_asMap(json['featured_spot'])),
      ecosystemItems: _asList(
        json['ecosystem_items'],
        ExploreEcosystemItem.fromJson,
      ),
    );
  }
}

class ExploreLayer {
  const ExploreLayer({
    required this.layerKey,
    required this.label,
    required this.iconKey,
    required this.accentKey,
  });

  final String layerKey;
  final String label;
  final String iconKey;
  final String accentKey;

  factory ExploreLayer.fromJson(Map<String, dynamic> json) {
    return ExploreLayer(
      layerKey: json['layer_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class ExploreSignal {
  const ExploreSignal({
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.iconKey,
    required this.accentKey,
  });

  final String title;
  final String subtitle;
  final String meta;
  final String iconKey;
  final String accentKey;

  factory ExploreSignal.fromJson(Map<String, dynamic> json) {
    return ExploreSignal(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      meta: json['meta']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class ExploreMapData {
  const ExploreMapData({
    required this.updatedLabel,
    required this.activeScore,
    required this.markers,
  });

  final String updatedLabel;
  final int activeScore;
  final List<ExploreMapMarker> markers;

  factory ExploreMapData.fromJson(Map<String, dynamic> json) {
    return ExploreMapData(
      updatedLabel: json['updated_label']?.toString() ?? '数据更新时间 --',
      activeScore: _asInt(json['active_score']) ?? 0,
      markers: _asList(json['markers'], ExploreMapMarker.fromJson),
    );
  }
}

class ExploreMapMarker {
  const ExploreMapMarker({
    required this.label,
    required this.value,
    required this.xRatio,
    required this.yRatio,
    required this.accentKey,
  });

  final String label;
  final String value;
  final double xRatio;
  final double yRatio;
  final String accentKey;

  factory ExploreMapMarker.fromJson(Map<String, dynamic> json) {
    return ExploreMapMarker(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      xRatio: _asDouble(json['x_ratio']),
      yRatio: _asDouble(json['y_ratio']),
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class ExploreFeaturedSpot {
  const ExploreFeaturedSpot({
    required this.title,
    required this.region,
    required this.gradeLabel,
    required this.metrics,
    required this.actionTitle,
    required this.actionSubtitle,
  });

  final String title;
  final String region;
  final String gradeLabel;
  final List<ExploreSpotMetric> metrics;
  final String actionTitle;
  final String actionSubtitle;

  factory ExploreFeaturedSpot.fromJson(Map<String, dynamic> json) {
    return ExploreFeaturedSpot(
      title: json['title']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      gradeLabel: json['grade_label']?.toString() ?? '',
      metrics: _asList(json['metrics'], ExploreSpotMetric.fromJson),
      actionTitle: json['action_title']?.toString() ?? '',
      actionSubtitle: json['action_subtitle']?.toString() ?? '',
    );
  }
}

class ExploreSpotMetric {
  const ExploreSpotMetric({
    required this.value,
    required this.label,
    required this.accentKey,
  });

  final String value;
  final String label;
  final String accentKey;

  factory ExploreSpotMetric.fromJson(Map<String, dynamic> json) {
    return ExploreSpotMetric(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class ExploreEcosystemItem {
  const ExploreEcosystemItem({
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.accentKey,
  });

  final String title;
  final String subtitle;
  final String iconKey;
  final String accentKey;

  factory ExploreEcosystemItem.fromJson(Map<String, dynamic> json) {
    return ExploreEcosystemItem(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
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

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '');
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
