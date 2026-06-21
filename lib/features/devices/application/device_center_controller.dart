import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/device_models.dart';
import '../data/device_center_demo_data.dart';
import '../data/device_center_models.dart';
import '../data/device_center_repository.dart';

enum DeviceDetailTab { status, control, automation, maintenance }

class DeviceControlState {
  const DeviceControlState({
    this.isSubmitting = false,
    this.latestReceipt,
    this.localDeviceState = const {},
    this.errorMessage = '',
  });

  final bool isSubmitting;
  final DeviceCommandReceipt? latestReceipt;
  final Map<String, dynamic> localDeviceState;
  final String errorMessage;

  bool get needsConfirmation => latestReceipt?.awaitingConfirmation == true;

  DeviceControlState copyWith({
    bool? isSubmitting,
    DeviceCommandReceipt? latestReceipt,
    Map<String, dynamic>? localDeviceState,
    String? errorMessage,
  }) {
    return DeviceControlState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      latestReceipt: latestReceipt ?? this.latestReceipt,
      localDeviceState: localDeviceState ?? this.localDeviceState,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  DeviceControlState withReceipt(DeviceCommandReceipt receipt) {
    final nextState = Map<String, dynamic>.from(localDeviceState);
    if (receipt.succeeded) {
      nextState.addAll(_statePatch(receipt));
    }
    return DeviceControlState(
      latestReceipt: receipt,
      localDeviceState: nextState,
      errorMessage: receipt.failureReason,
    );
  }
}

Map<String, dynamic> _statePatch(DeviceCommandReceipt receipt) {
  final parameters = receipt.result.isNotEmpty
      ? receipt.result
      : receipt.parameters;
  return switch (receipt.command) {
    'set_light' => {'light_enabled': parameters['enabled'] ?? true},
    'set_usb_power' => {'usb_power_enabled': parameters['enabled'] ?? true},
    'set_lock' => {'locked': parameters['locked'] ?? true},
    'set_temperature' => {'target_temperature': parameters['temperature']},
    'set_cooling_mode' => {'cooling_mode': parameters['mode']},
    'open_umbrella' => {'umbrella_open': true},
    'close_umbrella' => {'umbrella_open': false},
    'set_tilt' => {'tilt_angle': parameters['angle']},
    'set_wind_threshold' => {'wind_threshold': parameters['level']},
    'set_automation' => parameters,
    'auto_level' => {'tilt_angle': 0},
    'adjust_leg' => {'leg_adjustment': parameters},
    'set_safety_lock' => {'safety_lock': parameters['enabled'] ?? true},
    'emergency_stop' => {'emergency_stopped': true},
    'calibrate' => {'calibrated': true},
    'firmware_upgrade' => {'firmware_version': parameters['target_version']},
    _ => parameters,
  };
}

class DeviceCenterState {
  const DeviceCenterState({
    required this.devices,
    required this.source,
    this.selectedDeviceId,
    this.filter = 'all',
  });

  final List<Device> devices;
  final String source;
  final String? selectedDeviceId;
  final String filter;

  List<Device> get visibleDevices {
    return switch (filter) {
      'alerts' =>
        devices
            .where((item) => item.alerts.isNotEmpty || item.isLowBattery)
            .toList(growable: false),
      'online' =>
        devices.where((item) => item.isOnline).toList(growable: false),
      _ => devices,
    };
  }

  DeviceCenterState copyWith({
    List<Device>? devices,
    String? source,
    String? selectedDeviceId,
    String? filter,
  }) {
    return DeviceCenterState(
      devices: devices ?? this.devices,
      source: source ?? this.source,
      selectedDeviceId: selectedDeviceId ?? this.selectedDeviceId,
      filter: filter ?? this.filter,
    );
  }
}

class DeviceCenterController extends AsyncNotifier<DeviceCenterState> {
  @override
  Future<DeviceCenterState> build() async {
    try {
      final result = await ref
          .read(deviceCenterRepositoryProvider)
          .fetchDevices();
      final selected = result.devices.isEmpty ? null : result.devices.first.id;
      return DeviceCenterState(
        devices: result.devices,
        source: 'api',
        selectedDeviceId: selected,
      );
    } catch (_) {
      final devices = demoDeviceCenterDevices;
      return DeviceCenterState(
        devices: devices,
        source: 'demo',
        selectedDeviceId: devices.isEmpty ? null : devices.first.id,
      );
    }
  }

  void selectDevice(String deviceId) {
    final value = state.value;
    if (value != null) {
      state = AsyncData(value.copyWith(selectedDeviceId: deviceId));
    }
  }

  void setFilter(String filter) {
    final value = state.value;
    if (value != null) state = AsyncData(value.copyWith(filter: filter));
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

class DeviceControlController extends Notifier<DeviceControlState> {
  DeviceControlController(this._deviceId);

  final String _deviceId;

  @override
  DeviceControlState build() {
    return const DeviceControlState();
  }

  Future<DeviceCommandReceipt?> issue(
    String command, {
    Map<String, dynamic> parameters = const {},
    bool confirmed = false,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final receipt = await ref
          .read(deviceCenterRepositoryProvider)
          .issueCommand(
            _deviceId,
            command,
            parameters: parameters,
            confirmed: confirmed,
          );
      state = state.withReceipt(receipt);
      return receipt;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: '命令下发失败，请检查设备连接后重试',
      );
      return null;
    }
  }
}

final deviceCenterProvider =
    AsyncNotifierProvider<DeviceCenterController, DeviceCenterState>(
      DeviceCenterController.new,
    );

final deviceDetailProvider = FutureProvider.family<DeviceDetailBundle, String>((
  ref,
  deviceId,
) {
  return ref.read(deviceCenterRepositoryProvider).fetchDeviceBundle(deviceId);
});

final deviceScenesProvider = FutureProvider<List<DeviceAutomationScene>>((ref) {
  return ref.read(deviceCenterRepositoryProvider).fetchScenes();
});

final deviceControlProvider =
    NotifierProvider.family<
      DeviceControlController,
      DeviceControlState,
      String
    >(DeviceControlController.new);
