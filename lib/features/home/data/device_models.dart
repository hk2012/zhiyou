import '../../../core/domain/app_domain_models.dart';

typedef DeviceTelemetry = DomainTelemetrySnapshot;
typedef DeviceAlert = DomainDeviceAlert;

/// Compatibility API model for the devices endpoint.
///
/// The canonical fields live in [DomainDevice]. Keeping this thin subclass lets
/// existing repositories keep their public type names while avoiding a second
/// hand-written device contract.
class Device extends DomainDevice {
  const Device({
    required super.id,
    required super.name,
    required super.type,
    required super.status,
    required super.sceneRole,
    required super.batteryLevel,
    required super.signalLevel,
    required super.telemetry,
    super.firmwareVersion = '',
    super.boundAt,
    super.lastSeenAt,
    super.alerts = const [],
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device.fromDomain(DomainDevice.fromJson(json));
  }

  factory Device.fromDomain(DomainDevice device) {
    return Device(
      id: device.id,
      name: device.name,
      type: device.type,
      status: device.status,
      sceneRole: device.sceneRole,
      batteryLevel: device.batteryLevel,
      signalLevel: device.signalLevel,
      telemetry: device.telemetry,
      firmwareVersion: device.firmwareVersion,
      boundAt: device.boundAt,
      lastSeenAt: device.lastSeenAt,
      alerts: device.alerts,
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
