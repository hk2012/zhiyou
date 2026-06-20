import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/app_domain_models.dart';
import '../../../core/network/dio_client.dart';
import '../data/device_mock_data.dart';
import '../data/device_repository.dart';

enum IotDeviceSource { localMock, api }

class IotDeviceLoadState {
  const IotDeviceLoadState({
    required this.source,
    required this.isLoading,
    required this.message,
    required this.lastSyncedAt,
  });

  const IotDeviceLoadState.initial()
    : source = IotDeviceSource.localMock,
      isLoading = false,
      message = '正在使用本地设备快照',
      lastSyncedAt = null;

  final IotDeviceSource source;
  final bool isLoading;
  final String message;
  final DateTime? lastSyncedAt;

  bool get isFromApi => source == IotDeviceSource.api;

  IotDeviceLoadState copyWith({
    IotDeviceSource? source,
    bool? isLoading,
    String? message,
    DateTime? lastSyncedAt,
  }) {
    return IotDeviceLoadState(
      source: source ?? this.source,
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

class IotDeviceLoadStateNotifier extends Notifier<IotDeviceLoadState> {
  @override
  IotDeviceLoadState build() {
    return const IotDeviceLoadState.initial();
  }

  void markLoading() {
    state = state.copyWith(isLoading: true, message: '正在同步后端设备数据');
  }

  void markApi() {
    state = IotDeviceLoadState(
      source: IotDeviceSource.api,
      isLoading: false,
      message: '设备数据来自后端 API',
      lastSyncedAt: DateTime.now(),
    );
  }

  void markFallback(String message) {
    state = IotDeviceLoadState(
      source: IotDeviceSource.localMock,
      isLoading: false,
      message: message,
      lastSyncedAt: DateTime.now(),
    );
  }
}

class IotDeviceState {
  const IotDeviceState({
    required this.id,
    required this.title,
    required this.type,
    required this.sceneRole,
    required this.telemetryLabel,
    required this.telemetryValue,
    required this.workingState,
    required this.batteryLevel,
    required this.signalLevel,
    required this.isActive,
    required this.riskLabel,
    required this.actionHint,
  });

  final String id;
  final String title;
  final String type;
  final String sceneRole;
  final String telemetryLabel;
  final String telemetryValue;
  final String workingState;
  final int batteryLevel;
  final int signalLevel;
  final bool isActive;
  final String riskLabel;
  final String actionHint;

  DomainDeviceType get domainType => domainDeviceTypeFromWire(type);

  DomainDeviceStatus get domainStatus {
    if (riskLabel == '未绑定') return DomainDeviceStatus.unbound;
    if (riskLabel == '离线') return DomainDeviceStatus.offline;
    if (!isActive) return DomainDeviceStatus.standby;
    if (riskLabel == '待校准' || riskLabel == '异常' || riskLabel == '低电量') {
      return DomainDeviceStatus.abnormal;
    }
    return DomainDeviceStatus.online;
  }

  DomainDevice toDomainDevice() {
    final alert = (riskLabel == '正常' || riskLabel == '可用')
        ? const <DomainDeviceAlert>[]
        : [
            DomainDeviceAlert(
              id: '${id}_alert',
              deviceId: id,
              severity: riskLabel == '待校准'
                  ? DomainAlertSeverity.warning
                  : DomainAlertSeverity.info,
              title: riskLabel,
              message: actionHint,
              actionLabel: riskLabel == '未绑定' ? '立即绑定' : '查看建议',
              createdAt: DateTime.now(),
            ),
          ];

    return DomainDevice(
      id: id,
      name: title,
      type: domainType,
      status: domainStatus,
      sceneRole: sceneRole,
      batteryLevel: batteryLevel,
      signalLevel: signalLevel,
      telemetry: [
        DomainTelemetrySnapshot(
          metricKey: _telemetryKey(type),
          label: telemetryLabel,
          value: telemetryValue,
          quality: riskLabel,
          observedAt: DateTime.now(),
        ),
      ],
      alerts: alert,
    );
  }

  IotDeviceState copyWith({
    String? workingState,
    String? telemetryValue,
    int? batteryLevel,
    int? signalLevel,
    bool? isActive,
    String? riskLabel,
    String? actionHint,
  }) {
    return IotDeviceState(
      id: id,
      title: title,
      type: type,
      sceneRole: sceneRole,
      telemetryLabel: telemetryLabel,
      telemetryValue: telemetryValue ?? this.telemetryValue,
      workingState: workingState ?? this.workingState,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      signalLevel: signalLevel ?? this.signalLevel,
      isActive: isActive ?? this.isActive,
      riskLabel: riskLabel ?? this.riskLabel,
      actionHint: actionHint ?? this.actionHint,
    );
  }
}

class IotDeviceSummary {
  const IotDeviceSummary({
    required this.onlineCount,
    required this.totalCount,
    required this.lowestBattery,
    required this.averageSignal,
    required this.warningCount,
    required this.coreDevice,
  });

  final int onlineCount;
  final int totalCount;
  final int lowestBattery;
  final int averageSignal;
  final int warningCount;
  final IotDeviceState coreDevice;
}

class IotDevicesNotifier extends Notifier<List<IotDeviceState>> {
  @override
  List<IotDeviceState> build() {
    return _fallbackIotDevices;
  }

  Future<bool> refreshFromApi({bool silent = false}) async {
    if (!silent) {
      ref.read(iotDeviceLoadStateProvider.notifier).markLoading();
    }

    try {
      final result = await ref.read(deviceRepositoryProvider).fetchDevices();
      if (result.devices.isEmpty) {
        state = _fallbackIotDevices;
        ref
            .read(iotDeviceLoadStateProvider.notifier)
            .markFallback('后端暂无绑定设备，已展示本地设备快照');
        return false;
      }

      state = result.devices.map(_mapDomainDevice).toList(growable: false);
      ref.read(iotDeviceLoadStateProvider.notifier).markApi();
      return true;
    } catch (error) {
      state = _fallbackIotDevices;
      ref
          .read(iotDeviceLoadStateProvider.notifier)
          .markFallback(_friendlyError(error));
      return false;
    }
  }

  void toggleDevice(String id) {
    state = state
        .map((device) {
          if (device.id != id) return device;
          final nextActive = !device.isActive;
          return device.copyWith(
            isActive: nextActive,
            workingState: nextActive ? _activeState(device.type) : '已转入待机',
            riskLabel: nextActive ? _riskLabel(device.signalLevel) : '待机',
          );
        })
        .toList(growable: false);
  }

  void syncSnapshot() {
    state = [
      for (final device in state)
        device.copyWith(
          signalLevel: (device.signalLevel + (device.isActive ? 3 : 1))
              .clamp(0, 100)
              .toInt(),
          batteryLevel: (device.batteryLevel - (device.isActive ? 1 : 0))
              .clamp(0, 100)
              .toInt(),
          riskLabel: device.isActive
              ? _riskLabel(device.signalLevel + 3)
              : '待机',
        ),
    ];
  }

  String _activeState(String type) {
    return switch (type) {
      'float' => '高灵敏监测',
      'sonar' => '扇面扫描中',
      'box' => '恒温保鲜',
      'umbrella' => '遮阳联动',
      'platform' => '自动调平',
      _ => '在线监测',
    };
  }

  String _riskLabel(int signalLevel) {
    if (signalLevel < 50) return '待校准';
    if (signalLevel < 72) return '提醒';
    return '正常';
  }
}

List<IotDeviceState> get _fallbackIotDevices {
  return mockFallbackDevices.map(_mapDomainDevice).toList(growable: false);
}

IotDeviceState _mapDomainDevice(DomainDevice device) {
  final telemetry = device.telemetry.isNotEmpty ? device.telemetry.first : null;
  final type = _legacyDeviceType(device.type);
  final riskLabel = _riskLabelFromDevice(device);

  return IotDeviceState(
    id: device.id,
    title: device.name,
    type: type,
    sceneRole: device.sceneRole.isNotEmpty
        ? device.sceneRole
        : _defaultSceneRole(type),
    telemetryLabel: telemetry?.label ?? _defaultTelemetryLabel(type),
    telemetryValue: telemetry?.value ?? '--',
    workingState: _workingStateFromDevice(device, type),
    batteryLevel: device.batteryLevel.clamp(0, 100).toInt(),
    signalLevel: device.signalLevel.clamp(0, 100).toInt(),
    isActive: _isActiveStatus(device.status),
    riskLabel: riskLabel,
    actionHint: _actionHintFromDevice(device, type, riskLabel),
  );
}

String _legacyDeviceType(DomainDeviceType type) {
  return switch (type) {
    DomainDeviceType.smartFloat => 'float',
    DomainDeviceType.smartTackleBox => 'box',
    DomainDeviceType.smartPlatform => 'platform',
    DomainDeviceType.smartUmbrella => 'umbrella',
    DomainDeviceType.fishFinder => 'sonar',
    _ => type.wireValue,
  };
}

bool _isActiveStatus(DomainDeviceStatus status) {
  return status == DomainDeviceStatus.online;
}

String _workingStateFromDevice(DomainDevice device, String type) {
  return switch (device.status) {
    DomainDeviceStatus.online => _activeStateLabel(type),
    DomainDeviceStatus.standby => '待机锁定',
    DomainDeviceStatus.abnormal => '需要处理',
    DomainDeviceStatus.offline => '离线',
    DomainDeviceStatus.unbound => '未绑定',
  };
}

String _riskLabelFromDevice(DomainDevice device) {
  final unresolvedAlerts = device.alerts.where((alert) => !alert.resolved);
  final critical = unresolvedAlerts.where(
    (alert) => alert.severity == DomainAlertSeverity.critical,
  );
  final warning = unresolvedAlerts.where(
    (alert) => alert.severity == DomainAlertSeverity.warning,
  );

  if (critical.isNotEmpty) return '异常';
  if (device.status == DomainDeviceStatus.offline) return '离线';
  if (device.status == DomainDeviceStatus.unbound) return '未绑定';
  if (device.status == DomainDeviceStatus.abnormal) return '异常';
  if (device.batteryLevel > 0 && device.batteryLevel <= 20) return '低电量';
  if (warning.isNotEmpty) {
    return warning.first.title.isNotEmpty ? warning.first.title : '提醒';
  }
  if (device.status == DomainDeviceStatus.standby) return '待机';
  return '正常';
}

String _actionHintFromDevice(
  DomainDevice device,
  String type,
  String riskLabel,
) {
  final actionableAlerts = device.alerts.where(
    (alert) => !alert.resolved && alert.message.isNotEmpty,
  );
  if (actionableAlerts.isNotEmpty) return actionableAlerts.first.message;
  if (riskLabel == '低电量') return '电量偏低，出发前建议充电或携带备用电源。';
  if (riskLabel == '离线') return '设备离线，建议检查蓝牙、网关或设备电源。';
  return _defaultActionHint(type);
}

String _defaultSceneRole(String type) {
  return switch (type) {
    'float' => '鱼口捕捉',
    'sonar' => '鱼层扫描',
    'box' => '鱼获保鲜',
    'umbrella' => '体感防护',
    'platform' => '岸边安全',
    _ => '设备监测',
  };
}

String _defaultTelemetryLabel(String type) {
  return switch (type) {
    'float' => '咬口频率',
    'sonar' => '鱼层',
    'box' => '箱内温度',
    'umbrella' => '紫外线',
    'platform' => '水平状态',
    _ => '设备状态',
  };
}

String _activeStateLabel(String type) {
  return switch (type) {
    'float' => '高灵敏监测',
    'sonar' => '扇面扫描中',
    'box' => '恒温保鲜',
    'umbrella' => '遮阳联动',
    'platform' => '自动调平',
    _ => '在线监测',
  };
}

String _defaultActionHint(String type) {
  return switch (type) {
    'float' => '轻口明显，建议保留小饵和慢节奏。',
    'sonar' => '中上层有信号，20 分钟无口就换层。',
    'box' => '鱼获记录后自动关联保鲜时长。',
    'umbrella' => '午后风变大时自动提示收伞。',
    'platform' => '到达钓位后先校准水平和锁定状态。',
    _ => '设备状态稳定，可按今日计划执行。',
  };
}

String _friendlyError(Object error) {
  if (error is DioException) {
    return '${DioClient.friendlyErrorMessage(error)}，已使用本地设备快照';
  }
  return '设备服务暂不可用，已使用本地设备快照';
}

final iotDevicesProvider =
    NotifierProvider<IotDevicesNotifier, List<IotDeviceState>>(
      IotDevicesNotifier.new,
    );

final iotDeviceLoadStateProvider =
    NotifierProvider<IotDeviceLoadStateNotifier, IotDeviceLoadState>(
      IotDeviceLoadStateNotifier.new,
    );

final iotDeviceSummaryProvider = Provider<IotDeviceSummary>((ref) {
  final devices = ref.watch(iotDevicesProvider);
  final safeDevices = devices.isEmpty ? _fallbackIotDevices : devices;
  final online = safeDevices.where((device) => device.isActive).length;
  final warning = safeDevices
      .where(
        (device) =>
            device.riskLabel == '提醒' ||
            device.riskLabel == '待校准' ||
            device.riskLabel == '异常' ||
            device.riskLabel == '低电量' ||
            device.riskLabel == '离线',
      )
      .length;
  final lowestBattery = safeDevices
      .map((device) => device.batteryLevel)
      .reduce((a, b) => a < b ? a : b);
  final averageSignal =
      safeDevices.map((device) => device.signalLevel).reduce((a, b) => a + b) ~/
      safeDevices.length;
  final coreDevice = safeDevices.firstWhere(
    (device) => device.type == 'float' && device.isActive,
    orElse: () => safeDevices.first,
  );

  return IotDeviceSummary(
    onlineCount: online,
    totalCount: safeDevices.length,
    lowestBattery: lowestBattery,
    averageSignal: averageSignal,
    warningCount: warning,
    coreDevice: coreDevice,
  );
});

final iotDomainDevicesProvider = Provider<List<DomainDevice>>((ref) {
  return ref
      .watch(iotDevicesProvider)
      .map((device) => device.toDomainDevice())
      .toList(growable: false);
});

final iotDomainDeviceSummaryProvider = Provider<DomainDeviceSummary>((ref) {
  return DomainDeviceSummary.fromDevices(ref.watch(iotDomainDevicesProvider));
});

String _telemetryKey(String type) {
  return switch (type) {
    'float' => 'bite_frequency',
    'sonar' => 'fish_layer',
    'box' => 'box_temperature',
    'umbrella' => 'uv_index',
    'platform' => 'level_offset',
    _ => 'device_state',
  };
}
