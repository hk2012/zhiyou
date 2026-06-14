class Device {
  const Device({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.sceneRole,
    required this.batteryLevel,
    required this.signalLevel,
    required this.telemetry,
    required this.alerts,
    this.firmwareVersion = '',
    this.boundAt,
    this.lastSeenAt,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String sceneRole;
  final int batteryLevel;
  final int signalLevel;
  final List<DeviceTelemetry> telemetry;
  final List<DeviceAlert> alerts;
  final String firmwareVersion;
  final DateTime? boundAt;
  final DateTime? lastSeenAt;

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: _asString(json['id']),
      name: _asString(json['name']),
      type: _asString(json['type']),
      status: _asString(json['status']),
      sceneRole: _asString(json['scene_role']),
      batteryLevel: _asInt(json['battery_level']),
      signalLevel: _asInt(json['signal_level']),
      telemetry: _asList(json['telemetry'], DeviceTelemetry.fromJson),
      alerts: _asList(json['alerts'], DeviceAlert.fromJson),
      firmwareVersion: _asString(json['firmware_version']),
      boundAt: _asDateTime(json['bound_at']),
      lastSeenAt: _asDateTime(json['last_seen_at']),
    );
  }
}

class DeviceTelemetry {
  const DeviceTelemetry({
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

  factory DeviceTelemetry.fromJson(Map<String, dynamic> json) {
    return DeviceTelemetry(
      metricKey: _asString(json['metric_key']),
      label: _asString(json['label']),
      value: _asString(json['value']),
      unit: _asString(json['unit']),
      numericValue: _asDoubleOrNull(json['numeric_value']),
      quality: _asString(json['quality'], fallback: 'normal'),
      observedAt: _asDateTime(json['observed_at']),
    );
  }
}

class DeviceAlert {
  const DeviceAlert({
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
  final String severity;
  final String title;
  final String message;
  final String actionLabel;
  final bool resolved;
  final DateTime? createdAt;

  factory DeviceAlert.fromJson(Map<String, dynamic> json) {
    return DeviceAlert(
      id: _asString(json['id']),
      deviceId: _asString(json['device_id']),
      severity: _asString(json['severity'], fallback: 'info'),
      title: _asString(json['title']),
      message: _asString(json['message']),
      actionLabel: _asString(json['action_label']),
      resolved: _asBool(json['resolved']),
      createdAt: _asDateTime(json['created_at']),
    );
  }
}

class FirmwareVersion {
  const FirmwareVersion({
    required this.deviceId,
    required this.deviceType,
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
    required this.mandatory,
    required this.releaseNotes,
    this.packageSizeMb,
    this.publishedAt,
  });

  final String deviceId;
  final String deviceType;
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
  final bool mandatory;
  final List<String> releaseNotes;
  final double? packageSizeMb;
  final DateTime? publishedAt;

  factory FirmwareVersion.fromJson(Map<String, dynamic> json) {
    return FirmwareVersion(
      deviceId: _asString(json['device_id']),
      deviceType: _asString(json['device_type']),
      currentVersion: _asString(json['current_version']),
      latestVersion: _asString(json['latest_version']),
      updateAvailable: _asBool(json['update_available']),
      mandatory: _asBool(json['mandatory']),
      releaseNotes: _asStringList(json['release_notes']),
      packageSizeMb: _asDoubleOrNull(json['package_size_mb']),
      publishedAt: _asDateTime(json['published_at']),
    );
  }
}

class DeviceListResult {
  const DeviceListResult({required this.devices, required this.source});

  final List<Device> devices;
  final String source;

  factory DeviceListResult.fromJson(Map<String, dynamic> json) {
    return DeviceListResult(
      devices: _asList(json['devices'], Device.fromJson),
      source: _asString(json['source'], fallback: 'api'),
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
  if (value is! List) return <T>[];
  return value.map((item) => fromJson(_asMap(item))).toList();
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

DateTime? _asDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}
