class MallSummary {
  const MallSummary({
    required this.categories,
    required this.heroSlides,
    required this.serviceItems,
    required this.trustItems,
    required this.partners,
  });

  final List<MallServiceCategory> categories;
  final List<MallHeroSlide> heroSlides;
  final List<MallServiceItem> serviceItems;
  final List<MallTrustItem> trustItems;
  final List<MallPartner> partners;

  factory MallSummary.fromJson(Map<String, dynamic> json) {
    return MallSummary(
      categories: _asList(json['categories'], MallServiceCategory.fromJson),
      heroSlides: _asList(json['hero_slides'], MallHeroSlide.fromJson),
      serviceItems: _asList(json['service_items'], MallServiceItem.fromJson),
      trustItems: _asList(json['trust_items'], MallTrustItem.fromJson),
      partners: _asList(json['partners'], MallPartner.fromJson),
    );
  }
}

class MallServiceCategory {
  const MallServiceCategory({
    required this.categoryKey,
    required this.label,
    required this.iconKey,
    required this.accentKey,
  });

  final String categoryKey;
  final String label;
  final String iconKey;
  final String accentKey;

  factory MallServiceCategory.fromJson(Map<String, dynamic> json) {
    return MallServiceCategory(
      categoryKey: json['category_key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class MallHeroSlide {
  const MallHeroSlide({
    required this.assetKey,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.unit,
    required this.action,
    required this.iconKey,
    required this.accentKey,
  });

  final String assetKey;
  final String tag;
  final String title;
  final String subtitle;
  final String price;
  final String unit;
  final String action;
  final String iconKey;
  final String accentKey;

  factory MallHeroSlide.fromJson(Map<String, dynamic> json) {
    return MallHeroSlide(
      assetKey: json['asset_key']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class MallServiceItem {
  const MallServiceItem({
    required this.categoryKey,
    required this.title,
    required this.description,
    required this.badge,
    required this.iconKey,
    required this.accentKey,
  });

  final String categoryKey;
  final String title;
  final String description;
  final String badge;
  final String iconKey;
  final String accentKey;

  factory MallServiceItem.fromJson(Map<String, dynamic> json) {
    return MallServiceItem(
      categoryKey: json['category_key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      badge: json['badge']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class MallTrustItem {
  const MallTrustItem({
    required this.title,
    required this.subtitle,
    required this.iconKey,
    required this.accentKey,
  });

  final String title;
  final String subtitle;
  final String iconKey;
  final String accentKey;

  factory MallTrustItem.fromJson(Map<String, dynamic> json) {
    return MallTrustItem(
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? '',
      accentKey: json['accent_key']?.toString() ?? '',
    );
  }
}

class MallPartner {
  const MallPartner({
    required this.name,
    required this.serviceScope,
    required this.rating,
    required this.accentKey,
    required this.verified,
  });

  final String name;
  final String serviceScope;
  final double rating;
  final String accentKey;
  final bool verified;

  factory MallPartner.fromJson(Map<String, dynamic> json) {
    return MallPartner(
      name: json['name']?.toString() ?? '',
      serviceScope: json['service_scope']?.toString() ?? '',
      rating: _asDouble(json['rating']),
      accentKey: json['accent_key']?.toString() ?? '',
      verified: json['verified'] == true,
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

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
