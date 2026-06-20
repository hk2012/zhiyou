import '../../../core/domain/app_domain_models.dart';

const mockFallbackDevices = <DomainDevice>[
  DomainDevice(
    id: 'float_fc_01',
    name: '智能鱼漂 FC-01',
    type: DomainDeviceType.smartFloat,
    status: DomainDeviceStatus.online,
    sceneRole: '鱼口捕捉',
    batteryLevel: 78,
    signalLevel: 91,
    telemetry: [
      DomainTelemetrySnapshot(
        metricKey: 'bite_frequency',
        label: '咬口频率',
        value: '6次/20分',
        quality: 'normal',
      ),
    ],
  ),
  DomainDevice(
    id: 'sonar_dp_02',
    name: '便携探鱼器 DP-02',
    type: DomainDeviceType.fishFinder,
    status: DomainDeviceStatus.online,
    sceneRole: '鱼层扫描',
    batteryLevel: 64,
    signalLevel: 84,
    telemetry: [
      DomainTelemetrySnapshot(
        metricKey: 'fish_layer',
        label: '鱼层',
        value: '1.8-2.4m',
        quality: 'normal',
      ),
    ],
  ),
  DomainDevice(
    id: 'box_cool_01',
    name: '智能钓箱 BOX-01',
    type: DomainDeviceType.smartTackleBox,
    status: DomainDeviceStatus.online,
    sceneRole: '鱼获保鲜',
    batteryLevel: 89,
    signalLevel: 76,
    telemetry: [
      DomainTelemetrySnapshot(
        metricKey: 'box_temperature',
        label: '箱内温度',
        value: '4°C',
        quality: 'normal',
      ),
    ],
  ),
  DomainDevice(
    id: 'umbrella_sun_01',
    name: '智能钓伞 U-01',
    type: DomainDeviceType.smartUmbrella,
    status: DomainDeviceStatus.online,
    sceneRole: '体感防护',
    batteryLevel: 72,
    signalLevel: 68,
    telemetry: [
      DomainTelemetrySnapshot(
        metricKey: 'uv_index',
        label: '紫外线',
        value: '中等',
        quality: 'normal',
      ),
    ],
    alerts: [
      DomainDeviceAlert(
        id: 'umbrella_sun_01_reminder',
        deviceId: 'umbrella_sun_01',
        severity: DomainAlertSeverity.warning,
        title: '提醒',
        message: '午后风变大时自动提示收伞。',
        actionLabel: '查看建议',
      ),
    ],
  ),
  DomainDevice(
    id: 'platform_lock_01',
    name: '智能钓台 P-01',
    type: DomainDeviceType.smartPlatform,
    status: DomainDeviceStatus.standby,
    sceneRole: '岸边安全',
    batteryLevel: 96,
    signalLevel: 42,
    telemetry: [
      DomainTelemetrySnapshot(
        metricKey: 'level_offset',
        label: '水平状态',
        value: '偏移 2°',
        quality: 'warning',
      ),
    ],
    alerts: [
      DomainDeviceAlert(
        id: 'platform_lock_01_calibration',
        deviceId: 'platform_lock_01',
        severity: DomainAlertSeverity.warning,
        title: '待校准',
        message: '到达钓位后先校准水平和锁定状态。',
        actionLabel: '立即校准',
      ),
    ],
  ),
];
