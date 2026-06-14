import '../../../core/domain/app_domain_models.dart';

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

enum MallProductCategory {
  smartDevice,
  smartFloat,
  smartTackleBox,
  smartPlatform,
  smartUmbrella,
  fishFinder,
  nightLight,
  bait,
  rod,
  fishingLine,
  accessory,
  membership,
  fishingVenue,
  sensor,
  oxygen,
}

extension MallProductCategoryMeta on MallProductCategory {
  String get key {
    switch (this) {
      case MallProductCategory.smartDevice:
        return 'smart_device';
      case MallProductCategory.smartFloat:
        return 'smart_float';
      case MallProductCategory.smartTackleBox:
        return 'smart_tackle_box';
      case MallProductCategory.smartPlatform:
        return 'smart_platform';
      case MallProductCategory.smartUmbrella:
        return 'smart_umbrella';
      case MallProductCategory.fishFinder:
        return 'fish_finder';
      case MallProductCategory.nightLight:
        return 'night_light';
      case MallProductCategory.bait:
        return 'bait';
      case MallProductCategory.rod:
        return 'rod';
      case MallProductCategory.fishingLine:
        return 'fishing_line';
      case MallProductCategory.accessory:
        return 'accessory';
      case MallProductCategory.membership:
        return 'membership';
      case MallProductCategory.fishingVenue:
        return 'fishing_venue';
      case MallProductCategory.sensor:
        return 'sensor';
      case MallProductCategory.oxygen:
        return 'oxygen';
    }
  }

  String get label {
    switch (this) {
      case MallProductCategory.smartDevice:
        return '智能设备';
      case MallProductCategory.smartFloat:
        return '智能鱼漂';
      case MallProductCategory.smartTackleBox:
        return '智能钓箱';
      case MallProductCategory.smartPlatform:
        return '智能钓台';
      case MallProductCategory.smartUmbrella:
        return '智能钓伞';
      case MallProductCategory.fishFinder:
        return '探鱼器';
      case MallProductCategory.nightLight:
        return '夜钓灯';
      case MallProductCategory.bait:
        return '饵料';
      case MallProductCategory.rod:
        return '鱼竿';
      case MallProductCategory.fishingLine:
        return '鱼线';
      case MallProductCategory.accessory:
        return '配件';
      case MallProductCategory.membership:
        return '会员套餐';
      case MallProductCategory.fishingVenue:
        return '钓场套餐';
      case MallProductCategory.sensor:
        return '传感器';
      case MallProductCategory.oxygen:
        return '增氧设备';
    }
  }

  bool get isSmartHardware {
    switch (this) {
      case MallProductCategory.smartDevice:
      case MallProductCategory.smartFloat:
      case MallProductCategory.smartTackleBox:
      case MallProductCategory.smartPlatform:
      case MallProductCategory.smartUmbrella:
      case MallProductCategory.fishFinder:
      case MallProductCategory.nightLight:
      case MallProductCategory.sensor:
      case MallProductCategory.oxygen:
        return true;
      case MallProductCategory.bait:
      case MallProductCategory.rod:
      case MallProductCategory.fishingLine:
      case MallProductCategory.accessory:
      case MallProductCategory.membership:
      case MallProductCategory.fishingVenue:
        return false;
    }
  }
}

class MallCategoryEntry {
  const MallCategoryEntry({
    required this.id,
    required this.label,
    required this.category,
    required this.subtitle,
    required this.priority,
  });

  final String id;
  final String label;
  final MallProductCategory category;
  final String subtitle;
  final int priority;
}

class MallProduct {
  const MallProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.price,
    required this.memberPrice,
    required this.originalPrice,
    required this.rating,
    required this.sales,
    required this.tags,
    required this.scene,
    required this.deviceCompatible,
    required this.features,
    required this.stock,
    required this.isSmartDevice,
    required this.isPackage,
    required this.packageItems,
    required this.supportMembershipDiscount,
    required this.supportDeviceLink,
    required this.recommendedFor,
    this.description = '',
    this.badge = '',
    this.suitableFish = const [],
    this.pairingProductIds = const [],
    this.reviews = const [],
    this.afterSale = '平台质保 / 7 天无理由',
    this.delivery = '24-48 小时发货',
    this.appFunctions = const [],
    this.batteryLife = '',
    this.waterproofLevel = '',
    this.firmwareUpgrade = '',
    this.warranty = '',
    this.bindingGuide = '',
  });

  final String id;
  final String name;
  final MallProductCategory category;
  final String image;
  final int price;
  final int memberPrice;
  final int originalPrice;
  final double rating;
  final int sales;
  final List<String> tags;
  final String scene;
  final List<String> deviceCompatible;
  final List<String> features;
  final int stock;
  final bool isSmartDevice;
  final bool isPackage;
  final List<MallPackageItem> packageItems;
  final bool supportMembershipDiscount;
  final bool supportDeviceLink;
  final List<String> recommendedFor;
  final String description;
  final String badge;
  final List<String> suitableFish;
  final List<String> pairingProductIds;
  final List<String> reviews;
  final String afterSale;
  final String delivery;
  final List<String> appFunctions;
  final String batteryLife;
  final String waterproofLevel;
  final String firmwareUpgrade;
  final String warranty;
  final String bindingGuide;

  DomainProduct toDomainProduct() {
    return DomainProduct(
      id: id,
      name: name,
      type: domainProductTypeFromWire(category.key),
      categoryKey: category.key,
      price: price,
      memberPrice: memberPrice,
      originalPrice: originalPrice,
      stock: stock,
      rating: rating,
      tags: tags,
      scene: scene,
      description: description,
      supportsMembershipDiscount: supportMembershipDiscount,
      supportsDeviceLink: supportDeviceLink,
      compatibleDeviceTypes: deviceCompatible
          .map(_domainDeviceTypeFromCommerceLabel)
          .toList(growable: false),
    );
  }
}

class MallPackageItem {
  const MallPackageItem({
    required this.name,
    required this.quantity,
    required this.value,
    this.productId = '',
  });

  final String name;
  final int quantity;
  final int value;
  final String productId;
}

class MallScenarioPackage {
  const MallScenarioPackage({
    required this.id,
    required this.name,
    required this.scene,
    required this.description,
    required this.coverImage,
    required this.originalPrice,
    required this.packagePrice,
    required this.memberPrice,
    required this.savingAmount,
    required this.tags,
    required this.items,
    required this.suitableFor,
    required this.mainBenefit,
    required this.rating,
    required this.sales,
  });

  final String id;
  final String name;
  final String scene;
  final String description;
  final String coverImage;
  final int originalPrice;
  final int packagePrice;
  final int memberPrice;
  final int savingAmount;
  final List<String> tags;
  final List<MallPackageItem> items;
  final List<String> suitableFor;
  final String mainBenefit;
  final double rating;
  final int sales;
}

class MallCoupon {
  const MallCoupon({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.threshold,
    required this.scene,
    required this.scopeProductIds,
    required this.expiresAt,
    this.memberOnly = false,
  });

  final String id;
  final String title;
  final String description;
  final int amount;
  final int threshold;
  final String scene;
  final List<String> scopeProductIds;
  final String expiresAt;
  final bool memberOnly;

  DomainCoupon toDomainCoupon() {
    return DomainCoupon(
      id: id,
      title: title,
      description: description,
      amount: amount,
      threshold: threshold,
      scene: scene,
      scopeProductIds: scopeProductIds,
      expiresAt: expiresAt,
      memberOnly: memberOnly,
    );
  }
}

class MallCartMockItem {
  const MallCartMockItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.selected,
    required this.addedFrom,
  });

  final String id;
  final String productId;
  final int quantity;
  final bool selected;
  final String addedFrom;

  DomainCartItem toDomainCartItem() {
    return DomainCartItem(
      id: id,
      productId: productId,
      quantity: quantity,
      selected: selected,
      addedFrom: addedFrom,
    );
  }
}

class MallMarketplaceMockSnapshot {
  const MallMarketplaceMockSnapshot({
    required this.categories,
    required this.products,
    required this.scenarioPackages,
    required this.coupons,
    required this.cartItems,
    required this.recommendedProductIds,
    required this.hotProductIds,
  });

  final List<MallCategoryEntry> categories;
  final List<MallProduct> products;
  final List<MallScenarioPackage> scenarioPackages;
  final List<MallCoupon> coupons;
  final List<MallCartMockItem> cartItems;
  final List<String> recommendedProductIds;
  final List<String> hotProductIds;
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

DomainDeviceType _domainDeviceTypeFromCommerceLabel(String value) {
  if (value.contains('鱼漂')) return DomainDeviceType.smartFloat;
  if (value.contains('钓箱')) return DomainDeviceType.smartTackleBox;
  if (value.contains('钓台')) return DomainDeviceType.smartPlatform;
  if (value.contains('钓伞')) return DomainDeviceType.smartUmbrella;
  if (value.contains('探鱼')) return DomainDeviceType.fishFinder;
  if (value.contains('夜钓灯')) return DomainDeviceType.nightLight;
  if (value.contains('App') || value.contains('中枢')) {
    return DomainDeviceType.hub;
  }
  return DomainDeviceType.other;
}
