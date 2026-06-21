import '../../../core/domain/app_domain_models.dart';
import '../../home/data/device_mock_data.dart';
import '../../home/data/device_models.dart';
import 'device_center_models.dart';

List<Device> get demoDeviceCenterDevices =>
    mockFallbackDevices.map(Device.fromDomain).toList(growable: false);

DeviceDetailBundle demoDeviceBundle(String deviceId) {
  final devices = demoDeviceCenterDevices;
  final device = devices.firstWhere(
    (item) => item.id == deviceId,
    orElse: () => devices.firstWhere(
      (item) => item.type == DomainDeviceType.smartTackleBox,
    ),
  );
  final capabilities = _demoCapabilities(device);
  return DeviceDetailBundle(
    device: device,
    capabilities: capabilities,
    telemetry: device.telemetry,
    alerts: device.alerts,
    firmware: FirmwareVersion(
      deviceId: device.id,
      deviceType: device.type.wireValue,
      currentVersion: device.firmwareVersion.isEmpty
          ? '1.0.0'
          : device.firmwareVersion,
      latestVersion: device.firmwareVersion.isEmpty
          ? '1.0.0'
          : device.firmwareVersion,
      updateAvailable: false,
      mandatory: false,
      releaseNotes: const ['当前为本地演示设备'],
    ),
    source: 'demo',
  );
}

List<DeviceAutomationScene> get demoDeviceScenes => const [
  DeviceAutomationScene(
    id: 'demo_departure',
    name: '开钓',
    description: '同步设备、开启钓伞并检查钓台水平',
    enabled: true,
    actions: [
      DeviceSceneAction(
        deviceId: 'umbrella_sun_01',
        command: 'open_umbrella',
        parameters: {},
        confirmed: true,
      ),
      DeviceSceneAction(
        deviceId: 'platform_lock_01',
        command: 'auto_level',
        parameters: {},
        confirmed: true,
      ),
    ],
  ),
  DeviceAutomationScene(
    id: 'demo_night',
    name: '夜钓',
    description: '保留低亮照明并加强安全提醒',
    enabled: true,
    actions: [],
  ),
  DeviceAutomationScene(
    id: 'demo_pack',
    name: '收竿',
    description: '收伞、锁箱并关闭输出电源',
    enabled: true,
    actions: [
      DeviceSceneAction(
        deviceId: 'umbrella_sun_01',
        command: 'close_umbrella',
        parameters: {},
        confirmed: true,
      ),
    ],
  ),
];

DeviceCapabilitySet _demoCapabilities(Device device) {
  final List<DeviceCapability> capabilities = switch (device.type) {
    DomainDeviceType.smartTackleBox => const [
      DeviceCapability(
        key: 'temperature',
        label: '当前温度',
        kind: DeviceCapabilityKind.property,
        valueType: 'number',
        unit: '°C',
      ),
      DeviceCapability(
        key: 'set_temperature',
        label: '目标温度',
        kind: DeviceCapabilityKind.command,
        valueType: 'number',
        unit: '°C',
        minimum: 0,
        maximum: 20,
      ),
      DeviceCapability(
        key: 'set_cooling_mode',
        label: '制冷模式',
        kind: DeviceCapabilityKind.command,
        valueType: 'enum',
        options: ['low', 'medium', 'high'],
      ),
      DeviceCapability(
        key: 'set_lock',
        label: '箱锁',
        kind: DeviceCapabilityKind.command,
        valueType: 'boolean',
        dangerLevel: DeviceDangerLevel.confirm,
      ),
      DeviceCapability(
        key: 'set_light',
        label: '照明',
        kind: DeviceCapabilityKind.command,
        valueType: 'boolean',
      ),
      DeviceCapability(
        key: 'set_usb_power',
        label: 'USB 电源',
        kind: DeviceCapabilityKind.command,
        valueType: 'boolean',
      ),
    ],
    DomainDeviceType.smartUmbrella => const [
      DeviceCapability(
        key: 'open_umbrella',
        label: '开伞',
        kind: DeviceCapabilityKind.command,
        valueType: 'action',
      ),
      DeviceCapability(
        key: 'close_umbrella',
        label: '收伞',
        kind: DeviceCapabilityKind.command,
        valueType: 'action',
        dangerLevel: DeviceDangerLevel.confirm,
      ),
      DeviceCapability(
        key: 'set_tilt',
        label: '倾角',
        kind: DeviceCapabilityKind.command,
        valueType: 'number',
        unit: '°',
        minimum: -45,
        maximum: 45,
      ),
      DeviceCapability(
        key: 'set_wind_threshold',
        label: '风力阈值',
        kind: DeviceCapabilityKind.command,
        valueType: 'number',
        unit: '级',
        minimum: 3,
        maximum: 8,
      ),
      DeviceCapability(
        key: 'set_automation',
        label: '自动化',
        kind: DeviceCapabilityKind.command,
        valueType: 'object',
      ),
    ],
    DomainDeviceType.smartPlatform => const [
      DeviceCapability(
        key: 'auto_level',
        label: '一键调平',
        kind: DeviceCapabilityKind.command,
        valueType: 'action',
      ),
      DeviceCapability(
        key: 'adjust_leg',
        label: '四腿微调',
        kind: DeviceCapabilityKind.command,
        valueType: 'object',
      ),
      DeviceCapability(
        key: 'set_safety_lock',
        label: '安全锁',
        kind: DeviceCapabilityKind.command,
        valueType: 'boolean',
        dangerLevel: DeviceDangerLevel.confirm,
      ),
      DeviceCapability(
        key: 'emergency_stop',
        label: '紧急停止',
        kind: DeviceCapabilityKind.command,
        valueType: 'action',
        dangerLevel: DeviceDangerLevel.critical,
      ),
      DeviceCapability(
        key: 'calibrate',
        label: '校准',
        kind: DeviceCapabilityKind.command,
        valueType: 'action',
      ),
    ],
    _ => const [],
  };
  return DeviceCapabilitySet(
    deviceId: device.id,
    deviceType: device.type,
    capabilities: capabilities,
  );
}
