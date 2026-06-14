/// Canonical business contracts shared by feature mock data, repositories, and
/// backend schemas. Existing UI models can adapt into these contracts gradually.
enum DomainDeviceType {
  smartFloat,
  smartTackleBox,
  smartPlatform,
  smartUmbrella,
  fishFinder,
  nightLight,
  hub,
  sensor,
  other,
}

extension DomainDeviceTypeX on DomainDeviceType {
  String get wireValue => switch (this) {
    DomainDeviceType.smartFloat => 'smart_float',
    DomainDeviceType.smartTackleBox => 'smart_tackle_box',
    DomainDeviceType.smartPlatform => 'smart_platform',
    DomainDeviceType.smartUmbrella => 'smart_umbrella',
    DomainDeviceType.fishFinder => 'fish_finder',
    DomainDeviceType.nightLight => 'night_light',
    DomainDeviceType.hub => 'hub',
    DomainDeviceType.sensor => 'sensor',
    DomainDeviceType.other => 'other',
  };

  String get label => switch (this) {
    DomainDeviceType.smartFloat => '智能鱼漂',
    DomainDeviceType.smartTackleBox => '智能钓箱',
    DomainDeviceType.smartPlatform => '智能钓台',
    DomainDeviceType.smartUmbrella => '智能钓伞',
    DomainDeviceType.fishFinder => '探鱼器',
    DomainDeviceType.nightLight => '夜钓灯',
    DomainDeviceType.hub => '连接中枢',
    DomainDeviceType.sensor => '传感器',
    DomainDeviceType.other => '其他设备',
  };
}

DomainDeviceType domainDeviceTypeFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'float' || 'smart_float' => DomainDeviceType.smartFloat,
    'box' ||
    'tackle_box' ||
    'smart_tackle_box' => DomainDeviceType.smartTackleBox,
    'platform' || 'smart_platform' => DomainDeviceType.smartPlatform,
    'umbrella' || 'smart_umbrella' => DomainDeviceType.smartUmbrella,
    'sonar' || 'fish_finder' => DomainDeviceType.fishFinder,
    'night_light' || 'light' => DomainDeviceType.nightLight,
    'hub' || 'gateway' => DomainDeviceType.hub,
    'sensor' => DomainDeviceType.sensor,
    _ => DomainDeviceType.other,
  };
}

enum DomainDeviceStatus { online, standby, offline, abnormal, unbound }

extension DomainDeviceStatusX on DomainDeviceStatus {
  String get wireValue => switch (this) {
    DomainDeviceStatus.online => 'online',
    DomainDeviceStatus.standby => 'standby',
    DomainDeviceStatus.offline => 'offline',
    DomainDeviceStatus.abnormal => 'abnormal',
    DomainDeviceStatus.unbound => 'unbound',
  };
}

DomainDeviceStatus domainDeviceStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'online' || 'active' || 'running' => DomainDeviceStatus.online,
    'standby' || 'idle' || 'waiting' => DomainDeviceStatus.standby,
    'abnormal' || 'warning' || 'error' => DomainDeviceStatus.abnormal,
    'unbound' || 'not_bound' => DomainDeviceStatus.unbound,
    _ => DomainDeviceStatus.offline,
  };
}

enum DomainAlertSeverity { info, warning, critical }

extension DomainAlertSeverityX on DomainAlertSeverity {
  String get wireValue => switch (this) {
    DomainAlertSeverity.info => 'info',
    DomainAlertSeverity.warning => 'warning',
    DomainAlertSeverity.critical => 'critical',
  };
}

DomainAlertSeverity domainAlertSeverityFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'critical' || 'danger' || 'error' => DomainAlertSeverity.critical,
    'warning' || 'warn' || 'remind' => DomainAlertSeverity.warning,
    _ => DomainAlertSeverity.info,
  };
}

class DomainTelemetrySnapshot {
  const DomainTelemetrySnapshot({
    required this.metricKey,
    required this.label,
    required this.value,
    this.unit = '',
    this.numericValue,
    this.quality = 'normal',
    this.observedAt,
  });

  final String metricKey;
  final String label;
  final String value;
  final String unit;
  final double? numericValue;
  final String quality;
  final DateTime? observedAt;

  factory DomainTelemetrySnapshot.fromJson(Map<String, dynamic> json) {
    return DomainTelemetrySnapshot(
      metricKey: _asString(json['metric_key']),
      label: _asString(json['label']),
      value: _asString(json['value']),
      unit: _asString(json['unit']),
      numericValue: _asDoubleOrNull(json['numeric_value']),
      quality: _asString(json['quality'], fallback: 'normal'),
      observedAt: _asDateTime(json['observed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'metric_key': metricKey,
    'label': label,
    'value': value,
    'unit': unit,
    'numeric_value': numericValue,
    'quality': quality,
    'observed_at': observedAt?.toIso8601String(),
  };
}

class DomainDeviceAlert {
  const DomainDeviceAlert({
    required this.id,
    required this.deviceId,
    required this.severity,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.resolved = false,
    this.createdAt,
  });

  final String id;
  final String deviceId;
  final DomainAlertSeverity severity;
  final String title;
  final String message;
  final String actionLabel;
  final bool resolved;
  final DateTime? createdAt;

  factory DomainDeviceAlert.fromJson(Map<String, dynamic> json) {
    return DomainDeviceAlert(
      id: _asString(json['id']),
      deviceId: _asString(json['device_id']),
      severity: domainAlertSeverityFromWire(json['severity']?.toString()),
      title: _asString(json['title']),
      message: _asString(json['message']),
      actionLabel: _asString(json['action_label']),
      resolved: _asBool(json['resolved']),
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'severity': severity.wireValue,
    'title': title,
    'message': message,
    'action_label': actionLabel,
    'resolved': resolved,
    'created_at': createdAt?.toIso8601String(),
  };
}

class DomainDevice {
  const DomainDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.sceneRole,
    required this.batteryLevel,
    required this.signalLevel,
    required this.telemetry,
    this.firmwareVersion = '',
    this.boundAt,
    this.lastSeenAt,
    this.alerts = const [],
  });

  final String id;
  final String name;
  final DomainDeviceType type;
  final DomainDeviceStatus status;
  final String sceneRole;
  final int batteryLevel;
  final int signalLevel;
  final List<DomainTelemetrySnapshot> telemetry;
  final String firmwareVersion;
  final DateTime? boundAt;
  final DateTime? lastSeenAt;
  final List<DomainDeviceAlert> alerts;

  bool get isOnline => status == DomainDeviceStatus.online;
  bool get isLowBattery => batteryLevel > 0 && batteryLevel <= 20;
  bool get hasAbnormalAlert =>
      status == DomainDeviceStatus.abnormal ||
      alerts.any((item) => item.severity == DomainAlertSeverity.critical);

  factory DomainDevice.fromJson(Map<String, dynamic> json) {
    return DomainDevice(
      id: _asString(json['id']),
      name: _asString(json['name']),
      type: domainDeviceTypeFromWire(json['type']?.toString()),
      status: domainDeviceStatusFromWire(json['status']?.toString()),
      sceneRole: _asString(json['scene_role']),
      batteryLevel: _asInt(json['battery_level']),
      signalLevel: _asInt(json['signal_level']),
      telemetry: _asList(json['telemetry'], DomainTelemetrySnapshot.fromJson),
      firmwareVersion: _asString(json['firmware_version']),
      boundAt: _asDateTime(json['bound_at']),
      lastSeenAt: _asDateTime(json['last_seen_at']),
      alerts: _asList(json['alerts'], DomainDeviceAlert.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.wireValue,
    'status': status.wireValue,
    'scene_role': sceneRole,
    'battery_level': batteryLevel,
    'signal_level': signalLevel,
    'telemetry': telemetry.map((item) => item.toJson()).toList(),
    'firmware_version': firmwareVersion,
    'bound_at': boundAt?.toIso8601String(),
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'alerts': alerts.map((item) => item.toJson()).toList(),
  };
}

class DomainDeviceSummary {
  const DomainDeviceSummary({
    required this.total,
    required this.online,
    required this.offline,
    required this.lowBattery,
    required this.abnormal,
    required this.lastSyncAt,
  });

  final int total;
  final int online;
  final int offline;
  final int lowBattery;
  final int abnormal;
  final DateTime? lastSyncAt;

  factory DomainDeviceSummary.fromDevices(List<DomainDevice> devices) {
    final online = devices.where((item) => item.isOnline).length;
    return DomainDeviceSummary(
      total: devices.length,
      online: online,
      offline: devices.length - online,
      lowBattery: devices.where((item) => item.isLowBattery).length,
      abnormal: devices.where((item) => item.hasAbnormalAlert).length,
      lastSyncAt: DateTime.now(),
    );
  }

  factory DomainDeviceSummary.fromJson(Map<String, dynamic> json) {
    return DomainDeviceSummary(
      total: _asInt(json['total']),
      online: _asInt(json['online']),
      offline: _asInt(json['offline']),
      lowBattery: _asInt(json['low_battery']),
      abnormal: _asInt(json['abnormal']),
      lastSyncAt: _asDateTime(json['last_sync_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'online': online,
    'offline': offline,
    'low_battery': lowBattery,
    'abnormal': abnormal,
    'last_sync_at': lastSyncAt?.toIso8601String(),
  };
}

enum DomainVenueStatus { open, paused, full, closed }

extension DomainVenueStatusX on DomainVenueStatus {
  String get wireValue => switch (this) {
    DomainVenueStatus.open => 'open',
    DomainVenueStatus.paused => 'paused',
    DomainVenueStatus.full => 'full',
    DomainVenueStatus.closed => 'closed',
  };
}

DomainVenueStatus domainVenueStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'open' || 'available' => DomainVenueStatus.open,
    'paused' || 'suspended' => DomainVenueStatus.paused,
    'full' || 'sold_out' => DomainVenueStatus.full,
    _ => DomainVenueStatus.closed,
  };
}

enum DomainSlotStatus { available, few, full }

extension DomainSlotStatusX on DomainSlotStatus {
  String get wireValue => switch (this) {
    DomainSlotStatus.available => 'available',
    DomainSlotStatus.few => 'few',
    DomainSlotStatus.full => 'full',
  };
}

DomainSlotStatus domainSlotStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'available' || 'open' => DomainSlotStatus.available,
    'few' || 'limited' => DomainSlotStatus.few,
    _ => DomainSlotStatus.full,
  };
}

enum DomainBookingStatus { pending, confirmed, cancelled, completed, failed }

extension DomainBookingStatusX on DomainBookingStatus {
  String get wireValue => switch (this) {
    DomainBookingStatus.pending => 'pending',
    DomainBookingStatus.confirmed => 'confirmed',
    DomainBookingStatus.cancelled => 'cancelled',
    DomainBookingStatus.completed => 'completed',
    DomainBookingStatus.failed => 'failed',
  };
}

DomainBookingStatus domainBookingStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'confirmed' || 'paid' => DomainBookingStatus.confirmed,
    'cancelled' || 'canceled' => DomainBookingStatus.cancelled,
    'completed' || 'used' => DomainBookingStatus.completed,
    'failed' => DomainBookingStatus.failed,
    _ => DomainBookingStatus.pending,
  };
}

class DomainVenueSlot {
  const DomainVenueSlot({
    required this.id,
    required this.venueId,
    required this.label,
    required this.timeRange,
    required this.price,
    required this.memberPrice,
    required this.leftSeats,
    this.status = DomainSlotStatus.available,
  });

  final String id;
  final String venueId;
  final String label;
  final String timeRange;
  final int price;
  final int memberPrice;
  final int leftSeats;
  final DomainSlotStatus status;

  factory DomainVenueSlot.fromJson(Map<String, dynamic> json) {
    return DomainVenueSlot(
      id: _asString(json['id']),
      venueId: _asString(json['venue_id']),
      label: _asString(json['label']),
      timeRange: _asString(json['time_range']),
      price: _asInt(json['price']),
      memberPrice: _asInt(json['member_price']),
      leftSeats: _asInt(json['left_seats']),
      status: domainSlotStatusFromWire(json['status']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venue_id': venueId,
    'label': label,
    'time_range': timeRange,
    'price': price,
    'member_price': memberPrice,
    'left_seats': leftSeats,
    'status': status.wireValue,
  };
}

class DomainVenuePackage {
  const DomainVenuePackage({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.price,
    required this.memberPrice,
    this.includes = const [],
  });

  final String id;
  final String venueId;
  final String title;
  final String description;
  final int price;
  final int memberPrice;
  final List<String> includes;

  factory DomainVenuePackage.fromJson(Map<String, dynamic> json) {
    return DomainVenuePackage(
      id: _asString(json['id']),
      venueId: _asString(json['venue_id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      price: _asInt(json['price']),
      memberPrice: _asInt(json['member_price']),
      includes: _asStringList(json['includes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venue_id': venueId,
    'title': title,
    'description': description,
    'price': price,
    'member_price': memberPrice,
    'includes': includes,
  };
}

class DomainVenueReview {
  const DomainVenueReview({
    required this.id,
    required this.venueId,
    required this.userName,
    required this.rating,
    required this.content,
    this.tags = const [],
  });

  final String id;
  final String venueId;
  final String userName;
  final double rating;
  final String content;
  final List<String> tags;

  factory DomainVenueReview.fromJson(Map<String, dynamic> json) {
    return DomainVenueReview(
      id: _asString(json['id']),
      venueId: _asString(json['venue_id']),
      userName: _asString(json['user_name']),
      rating: _asDouble(json['rating']),
      content: _asString(json['content']),
      tags: _asStringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venue_id': venueId,
    'user_name': userName,
    'rating': rating,
    'content': content,
    'tags': tags,
  };
}

class DomainVenue {
  const DomainVenue({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.status,
    required this.distanceKm,
    required this.rating,
    required this.priceFrom,
    required this.memberPriceFrom,
    required this.todayIndex,
    required this.fishSpecies,
    required this.tags,
    required this.supportsBooking,
    required this.supportsNightFishing,
    required this.supportsSmartDevice,
    this.summary = '',
    this.openHours = '',
    this.facilities = const [],
    this.recommendedDeviceTypes = const [],
    this.packages = const [],
    this.slots = const [],
    this.reviews = const [],
  });

  final String id;
  final String name;
  final String area;
  final String address;
  final DomainVenueStatus status;
  final double distanceKm;
  final double rating;
  final int priceFrom;
  final int memberPriceFrom;
  final int todayIndex;
  final List<String> fishSpecies;
  final List<String> tags;
  final bool supportsBooking;
  final bool supportsNightFishing;
  final bool supportsSmartDevice;
  final String summary;
  final String openHours;
  final List<String> facilities;
  final List<DomainDeviceType> recommendedDeviceTypes;
  final List<DomainVenuePackage> packages;
  final List<DomainVenueSlot> slots;
  final List<DomainVenueReview> reviews;

  factory DomainVenue.fromJson(Map<String, dynamic> json) {
    return DomainVenue(
      id: _asString(json['id']),
      name: _asString(json['name']),
      area: _asString(json['area']),
      address: _asString(json['address']),
      status: domainVenueStatusFromWire(json['status']?.toString()),
      distanceKm: _asDouble(json['distance_km']),
      rating: _asDouble(json['rating']),
      priceFrom: _asInt(json['price_from']),
      memberPriceFrom: _asInt(json['member_price_from']),
      todayIndex: _asInt(json['today_index']),
      fishSpecies: _asStringList(json['fish_species']),
      tags: _asStringList(json['tags']),
      supportsBooking: _asBool(json['supports_booking']),
      supportsNightFishing: _asBool(json['supports_night_fishing']),
      supportsSmartDevice: _asBool(json['supports_smart_device']),
      summary: _asString(json['summary']),
      openHours: _asString(json['open_hours']),
      facilities: _asStringList(json['facilities']),
      recommendedDeviceTypes: _asStringList(
        json['recommended_device_types'],
      ).map(domainDeviceTypeFromWire).toList(),
      packages: _asList(json['packages'], DomainVenuePackage.fromJson),
      slots: _asList(json['slots'], DomainVenueSlot.fromJson),
      reviews: _asList(json['reviews'], DomainVenueReview.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'area': area,
    'address': address,
    'status': status.wireValue,
    'distance_km': distanceKm,
    'rating': rating,
    'price_from': priceFrom,
    'member_price_from': memberPriceFrom,
    'today_index': todayIndex,
    'fish_species': fishSpecies,
    'tags': tags,
    'supports_booking': supportsBooking,
    'supports_night_fishing': supportsNightFishing,
    'supports_smart_device': supportsSmartDevice,
    'summary': summary,
    'open_hours': openHours,
    'facilities': facilities,
    'recommended_device_types': recommendedDeviceTypes
        .map((item) => item.wireValue)
        .toList(),
    'packages': packages.map((item) => item.toJson()).toList(),
    'slots': slots.map((item) => item.toJson()).toList(),
    'reviews': reviews.map((item) => item.toJson()).toList(),
  };
}

class DomainVenueBooking {
  const DomainVenueBooking({
    required this.id,
    required this.venueId,
    required this.slotId,
    required this.userId,
    required this.status,
    required this.amount,
    this.bookingDate = '',
    this.contactPhone = '',
  });

  final String id;
  final String venueId;
  final String slotId;
  final String userId;
  final DomainBookingStatus status;
  final int amount;
  final String bookingDate;
  final String contactPhone;

  factory DomainVenueBooking.fromJson(Map<String, dynamic> json) {
    return DomainVenueBooking(
      id: _asString(json['id']),
      venueId: _asString(json['venue_id']),
      slotId: _asString(json['slot_id']),
      userId: _asString(json['user_id']),
      status: domainBookingStatusFromWire(json['status']?.toString()),
      amount: _asInt(json['amount']),
      bookingDate: _asString(json['booking_date']),
      contactPhone: _asString(json['contact_phone']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venue_id': venueId,
    'slot_id': slotId,
    'user_id': userId,
    'status': status.wireValue,
    'amount': amount,
    'booking_date': bookingDate,
    'contact_phone': contactPhone,
  };
}

enum DomainProductType {
  device,
  accessory,
  bait,
  venuePackage,
  membership,
  service,
}

extension DomainProductTypeX on DomainProductType {
  String get wireValue => switch (this) {
    DomainProductType.device => 'device',
    DomainProductType.accessory => 'accessory',
    DomainProductType.bait => 'bait',
    DomainProductType.venuePackage => 'venue_package',
    DomainProductType.membership => 'membership',
    DomainProductType.service => 'service',
  };
}

DomainProductType domainProductTypeFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'smart_device' ||
    'smart_float' ||
    'smart_tackle_box' ||
    'smart_platform' ||
    'smart_umbrella' ||
    'fish_finder' ||
    'sensor' ||
    'oxygen' => DomainProductType.device,
    'bait' => DomainProductType.bait,
    'fishing_venue' || 'venue_package' => DomainProductType.venuePackage,
    'membership' => DomainProductType.membership,
    'accessory' || 'rod' || 'fishing_line' => DomainProductType.accessory,
    _ => DomainProductType.service,
  };
}

class DomainProduct {
  const DomainProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryKey,
    required this.price,
    required this.memberPrice,
    required this.originalPrice,
    required this.stock,
    required this.rating,
    this.tags = const [],
    this.scene = '',
    this.description = '',
    this.supportsMembershipDiscount = false,
    this.supportsDeviceLink = false,
    this.compatibleDeviceTypes = const [],
  });

  final String id;
  final String name;
  final DomainProductType type;
  final String categoryKey;
  final int price;
  final int memberPrice;
  final int originalPrice;
  final int stock;
  final double rating;
  final List<String> tags;
  final String scene;
  final String description;
  final bool supportsMembershipDiscount;
  final bool supportsDeviceLink;
  final List<DomainDeviceType> compatibleDeviceTypes;

  factory DomainProduct.fromJson(Map<String, dynamic> json) {
    return DomainProduct(
      id: _asString(json['id']),
      name: _asString(json['name']),
      type: domainProductTypeFromWire(json['type']?.toString()),
      categoryKey: _asString(json['category_key']),
      price: _asInt(json['price']),
      memberPrice: _asInt(json['member_price']),
      originalPrice: _asInt(json['original_price']),
      stock: _asInt(json['stock']),
      rating: _asDouble(json['rating']),
      tags: _asStringList(json['tags']),
      scene: _asString(json['scene']),
      description: _asString(json['description']),
      supportsMembershipDiscount: _asBool(json['supports_membership_discount']),
      supportsDeviceLink: _asBool(json['supports_device_link']),
      compatibleDeviceTypes: _asStringList(
        json['compatible_device_types'],
      ).map(domainDeviceTypeFromWire).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.wireValue,
    'category_key': categoryKey,
    'price': price,
    'member_price': memberPrice,
    'original_price': originalPrice,
    'stock': stock,
    'rating': rating,
    'tags': tags,
    'scene': scene,
    'description': description,
    'supports_membership_discount': supportsMembershipDiscount,
    'supports_device_link': supportsDeviceLink,
    'compatible_device_types': compatibleDeviceTypes
        .map((item) => item.wireValue)
        .toList(),
  };
}

class DomainCartItem {
  const DomainCartItem({
    required this.id,
    required this.productId,
    required this.quantity,
    this.selected = true,
    this.addedFrom = '',
  });

  final String id;
  final String productId;
  final int quantity;
  final bool selected;
  final String addedFrom;

  factory DomainCartItem.fromJson(Map<String, dynamic> json) {
    return DomainCartItem(
      id: _asString(json['id']),
      productId: _asString(json['product_id']),
      quantity: _asInt(json['quantity']),
      selected: _asBool(json['selected'], fallback: true),
      addedFrom: _asString(json['added_from']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'quantity': quantity,
    'selected': selected,
    'added_from': addedFrom,
  };
}

enum DomainOrderStatus {
  pendingPayment,
  pendingShipment,
  pendingReceipt,
  completed,
  refunded,
  cancelled,
}

extension DomainOrderStatusX on DomainOrderStatus {
  String get wireValue => switch (this) {
    DomainOrderStatus.pendingPayment => 'pending_payment',
    DomainOrderStatus.pendingShipment => 'pending_shipment',
    DomainOrderStatus.pendingReceipt => 'pending_receipt',
    DomainOrderStatus.completed => 'completed',
    DomainOrderStatus.refunded => 'refunded',
    DomainOrderStatus.cancelled => 'cancelled',
  };
}

DomainOrderStatus domainOrderStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'pending_shipment' => DomainOrderStatus.pendingShipment,
    'pending_receipt' => DomainOrderStatus.pendingReceipt,
    'completed' => DomainOrderStatus.completed,
    'refunded' || 'refund_after_sale' => DomainOrderStatus.refunded,
    'cancelled' || 'canceled' => DomainOrderStatus.cancelled,
    _ => DomainOrderStatus.pendingPayment,
  };
}

class DomainOrderLine {
  const DomainOrderLine({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
  });

  final String productId;
  final String title;
  final int quantity;
  final int price;

  factory DomainOrderLine.fromJson(Map<String, dynamic> json) {
    return DomainOrderLine(
      productId: _asString(json['product_id']),
      title: _asString(json['title']),
      quantity: _asInt(json['quantity']),
      price: _asInt(json['price']),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'title': title,
    'quantity': quantity,
    'price': price,
  };
}

class DomainOrder {
  const DomainOrder({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.amount,
    required this.lines,
    this.createdAt,
  });

  final String id;
  final String orderNo;
  final DomainOrderStatus status;
  final int amount;
  final List<DomainOrderLine> lines;
  final DateTime? createdAt;

  factory DomainOrder.fromJson(Map<String, dynamic> json) {
    return DomainOrder(
      id: _asString(json['id']),
      orderNo: _asString(json['order_no']),
      status: domainOrderStatusFromWire(json['status']?.toString()),
      amount: _asInt(json['amount']),
      lines: _asList(json['lines'], DomainOrderLine.fromJson),
      createdAt: _asDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_no': orderNo,
    'status': status.wireValue,
    'amount': amount,
    'lines': lines.map((item) => item.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
  };
}

class DomainCoupon {
  const DomainCoupon({
    required this.id,
    required this.title,
    required this.amount,
    required this.threshold,
    required this.scene,
    this.description = '',
    this.scopeProductIds = const [],
    this.expiresAt = '',
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

  factory DomainCoupon.fromJson(Map<String, dynamic> json) {
    return DomainCoupon(
      id: _asString(json['id']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      amount: _asInt(json['amount']),
      threshold: _asInt(json['threshold']),
      scene: _asString(json['scene']),
      scopeProductIds: _asStringList(json['scope_product_ids']),
      expiresAt: _asString(json['expires_at']),
      memberOnly: _asBool(json['member_only']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'amount': amount,
    'threshold': threshold,
    'scene': scene,
    'scope_product_ids': scopeProductIds,
    'expires_at': expiresAt,
    'member_only': memberOnly,
  };
}

class DomainAfterSaleTicket {
  const DomainAfterSaleTicket({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.title,
  });

  final String id;
  final String orderId;
  final String type;
  final String status;
  final String title;

  factory DomainAfterSaleTicket.fromJson(Map<String, dynamic> json) {
    return DomainAfterSaleTicket(
      id: _asString(json['id']),
      orderId: _asString(json['order_id']),
      type: _asString(json['type']),
      status: _asString(json['status']),
      title: _asString(json['title']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'type': type,
    'status': status,
    'title': title,
  };
}

enum DomainMembershipStatus { inactive, active, expired }

extension DomainMembershipStatusX on DomainMembershipStatus {
  String get wireValue => switch (this) {
    DomainMembershipStatus.inactive => 'inactive',
    DomainMembershipStatus.active => 'active',
    DomainMembershipStatus.expired => 'expired',
  };
}

DomainMembershipStatus domainMembershipStatusFromWire(String? value) {
  final normalized = _normalizeKey(value);
  return switch (normalized) {
    'active' || 'enabled' => DomainMembershipStatus.active,
    'expired' => DomainMembershipStatus.expired,
    _ => DomainMembershipStatus.inactive,
  };
}

class DomainMembership {
  const DomainMembership({
    required this.planId,
    required this.name,
    required this.status,
    this.expireAt = '',
    this.benefits = const [],
    this.summary = '',
  });

  final String planId;
  final String name;
  final DomainMembershipStatus status;
  final String expireAt;
  final List<String> benefits;
  final String summary;

  factory DomainMembership.fromJson(Map<String, dynamic> json) {
    return DomainMembership(
      planId: _asString(json['plan_id']),
      name: _asString(json['name']),
      status: domainMembershipStatusFromWire(json['status']?.toString()),
      expireAt: _asString(json['expire_at']),
      benefits: _asStringList(json['benefits']),
      summary: _asString(json['summary']),
    );
  }

  Map<String, dynamic> toJson() => {
    'plan_id': planId,
    'name': name,
    'status': status.wireValue,
    'expire_at': expireAt,
    'benefits': benefits,
    'summary': summary,
  };
}

class DomainUserAssetSummary {
  const DomainUserAssetSummary({
    required this.userId,
    required this.devices,
    required this.ordersTotal,
    required this.activeBookings,
    required this.fishingRecords,
    required this.availableCoupons,
    required this.points,
    required this.favorites,
    required this.membership,
  });

  final String userId;
  final DomainDeviceSummary devices;
  final int ordersTotal;
  final int activeBookings;
  final int fishingRecords;
  final int availableCoupons;
  final int points;
  final int favorites;
  final DomainMembership membership;

  factory DomainUserAssetSummary.fromJson(Map<String, dynamic> json) {
    return DomainUserAssetSummary(
      userId: _asString(json['user_id']),
      devices: DomainDeviceSummary.fromJson(_asMap(json['devices'])),
      ordersTotal: _asInt(json['orders_total']),
      activeBookings: _asInt(json['active_bookings']),
      fishingRecords: _asInt(json['fishing_records']),
      availableCoupons: _asInt(json['available_coupons']),
      points: _asInt(json['points']),
      favorites: _asInt(json['favorites']),
      membership: DomainMembership.fromJson(_asMap(json['membership'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'devices': devices.toJson(),
    'orders_total': ordersTotal,
    'active_bookings': activeBookings,
    'fishing_records': fishingRecords,
    'available_coupons': availableCoupons,
    'points': points,
    'favorites': favorites,
    'membership': membership.toJson(),
  };
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

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(dynamic value) => _asDoubleOrNull(value) ?? 0;

double? _asDoubleOrNull(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = _normalizeKey(value?.toString());
  if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'no' || normalized == '0') {
    return false;
  }
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

String _normalizeKey(String? value) {
  return value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
}
