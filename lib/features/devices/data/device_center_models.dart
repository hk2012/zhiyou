import '../../../core/domain/app_domain_models.dart';
import '../../home/data/device_models.dart';

enum DeviceCapabilityKind { property, command }

enum DeviceDangerLevel { normal, confirm, critical }

class DeviceCapability {
  const DeviceCapability({
    required this.key,
    required this.label,
    required this.kind,
    required this.valueType,
    this.unit = '',
    this.dangerLevel = DeviceDangerLevel.normal,
    this.options = const [],
    this.minimum,
    this.maximum,
  });

  final String key;
  final String label;
  final DeviceCapabilityKind kind;
  final String valueType;
  final String unit;
  final DeviceDangerLevel dangerLevel;
  final List<String> options;
  final double? minimum;
  final double? maximum;

  bool get requiresConfirmation => dangerLevel != DeviceDangerLevel.normal;

  factory DeviceCapability.fromJson(Map<String, dynamic> json) {
    return DeviceCapability(
      key: _string(json['key']),
      label: _string(json['label']),
      kind: _string(json['kind']) == 'command'
          ? DeviceCapabilityKind.command
          : DeviceCapabilityKind.property,
      valueType: _string(json['value_type']),
      unit: _string(json['unit']),
      dangerLevel: switch (_string(json['danger_level'])) {
        'critical' => DeviceDangerLevel.critical,
        'confirm' => DeviceDangerLevel.confirm,
        _ => DeviceDangerLevel.normal,
      },
      options: _stringList(json['options']),
      minimum: _double(json['minimum']),
      maximum: _double(json['maximum']),
    );
  }
}

class DeviceCapabilitySet {
  const DeviceCapabilitySet({
    required this.deviceId,
    required this.deviceType,
    required this.capabilities,
  });

  final String deviceId;
  final DomainDeviceType deviceType;
  final List<DeviceCapability> capabilities;

  factory DeviceCapabilitySet.fromJson(Map<String, dynamic> json) {
    return DeviceCapabilitySet(
      deviceId: _string(json['device_id']),
      deviceType: domainDeviceTypeFromWire(_string(json['device_type'])),
      capabilities: _mapList(json['capabilities'], DeviceCapability.fromJson),
    );
  }

  DeviceCapability? command(String key) {
    for (final item in capabilities) {
      if (item.kind == DeviceCapabilityKind.command && item.key == key) {
        return item;
      }
    }
    return null;
  }
}

class DeviceCommandTimelineItem {
  const DeviceCommandTimelineItem({
    required this.status,
    required this.at,
    required this.message,
  });

  final String status;
  final DateTime? at;
  final String message;

  factory DeviceCommandTimelineItem.fromJson(Map<String, dynamic> json) {
    return DeviceCommandTimelineItem(
      status: _string(json['status']),
      at: DateTime.tryParse(_string(json['at'])),
      message: _string(json['message']),
    );
  }
}

class DeviceCommandReceipt {
  const DeviceCommandReceipt({
    required this.commandId,
    required this.deviceId,
    required this.command,
    required this.status,
    required this.dangerous,
    required this.parameters,
    required this.result,
    required this.timeline,
    required this.failureReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String commandId;
  final String deviceId;
  final String command;
  final String status;
  final bool dangerous;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> result;
  final List<DeviceCommandTimelineItem> timeline;
  final String failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get succeeded => status == 'succeeded';
  bool get awaitingConfirmation => status == 'awaiting_confirmation';
  bool get isTerminal => {
    'succeeded',
    'failed',
    'timed_out',
    'rejected',
    'cancelled',
  }.contains(status);

  factory DeviceCommandReceipt.fromJson(Map<String, dynamic> json) {
    return DeviceCommandReceipt(
      commandId: _string(json['command_id']),
      deviceId: _string(json['device_id']),
      command: _string(json['command']),
      status: _string(json['status']),
      dangerous: _boolean(json['dangerous']),
      parameters: _map(json['parameters']),
      result: _map(json['result']),
      timeline: _mapList(json['timeline'], DeviceCommandTimelineItem.fromJson),
      failureReason: _string(json['failure_reason']),
      createdAt: DateTime.tryParse(_string(json['created_at'])),
      updatedAt: DateTime.tryParse(_string(json['updated_at'])),
    );
  }
}

class DeviceSceneAction {
  const DeviceSceneAction({
    required this.deviceId,
    required this.command,
    required this.parameters,
    required this.confirmed,
  });

  final String deviceId;
  final String command;
  final Map<String, dynamic> parameters;
  final bool confirmed;

  factory DeviceSceneAction.fromJson(Map<String, dynamic> json) {
    return DeviceSceneAction(
      deviceId: _string(json['device_id']),
      command: _string(json['command']),
      parameters: _map(json['parameters']),
      confirmed: _boolean(json['confirmed']),
    );
  }

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'command': command,
    'parameters': parameters,
    'confirmed': confirmed,
  };
}

class DeviceAutomationScene {
  const DeviceAutomationScene({
    required this.id,
    required this.name,
    required this.description,
    required this.enabled,
    required this.actions,
    this.lastExecutedAt,
  });

  final String id;
  final String name;
  final String description;
  final bool enabled;
  final List<DeviceSceneAction> actions;
  final DateTime? lastExecutedAt;

  factory DeviceAutomationScene.fromJson(Map<String, dynamic> json) {
    return DeviceAutomationScene(
      id: _string(json['id']),
      name: _string(json['name']),
      description: _string(json['description']),
      enabled: _boolean(json['enabled'], fallback: true),
      actions: _mapList(json['actions'], DeviceSceneAction.fromJson),
      lastExecutedAt: DateTime.tryParse(_string(json['last_executed_at'])),
    );
  }
}

class DeviceSceneExecution {
  const DeviceSceneExecution({
    required this.sceneId,
    required this.status,
    required this.commands,
  });

  final String sceneId;
  final String status;
  final List<DeviceCommandReceipt> commands;

  bool get succeeded => status == 'succeeded';

  factory DeviceSceneExecution.fromJson(Map<String, dynamic> json) {
    return DeviceSceneExecution(
      sceneId: _string(json['scene_id']),
      status: _string(json['status']),
      commands: _mapList(json['commands'], DeviceCommandReceipt.fromJson),
    );
  }
}

class DeviceDetailBundle {
  const DeviceDetailBundle({
    required this.device,
    required this.capabilities,
    required this.telemetry,
    required this.alerts,
    required this.firmware,
    required this.source,
  });

  final Device device;
  final DeviceCapabilitySet capabilities;
  final List<DeviceTelemetry> telemetry;
  final List<DeviceAlert> alerts;
  final FirmwareVersion firmware;
  final String source;

  bool get isDemo => source != 'api';
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<T> _mapList<T>(dynamic value, T Function(Map<String, dynamic>) builder) {
  if (value is! List) return <T>[];
  return value.map((item) => builder(_map(item))).toList(growable: false);
}

String _string(dynamic value) => value?.toString() ?? '';

bool _boolean(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return {'true', '1', 'yes'}.contains(value.toString().toLowerCase());
}

double? _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value.map((item) => item.toString()).toList(growable: false);
}
