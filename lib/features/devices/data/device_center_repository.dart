import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../home/data/device_models.dart';
import '../../home/data/device_repository.dart';
import 'device_center_demo_data.dart';
import 'device_center_models.dart';

final deviceCenterRepositoryProvider = Provider<DeviceCenterRepository>((ref) {
  return DeviceCenterRepository(DioClient.instance);
});

class DeviceCenterRepository {
  const DeviceCenterRepository(this._dio);

  final Dio _dio;

  Future<DeviceListResult> fetchDevices() async {
    return DeviceRepository(_dio).fetchDevices();
  }

  Future<DeviceDetailBundle> fetchDeviceBundle(String deviceId) async {
    final base = DeviceRepository(_dio);
    try {
      final values = await Future.wait([
        base.fetchDevice(deviceId),
        _dio.get<Map<String, dynamic>>(
          '/api/v1/devices/$deviceId/capabilities',
        ),
        base.fetchTelemetry(deviceId, limit: 48),
        base.fetchAlerts(deviceId, includeResolved: true),
        base.fetchFirmware(deviceId),
      ]);
      return DeviceDetailBundle(
        device: values[0] as Device,
        capabilities: DeviceCapabilitySet.fromJson(
          (values[1] as Response<Map<String, dynamic>>).data ?? {},
        ),
        telemetry: values[2] as List<DeviceTelemetry>,
        alerts: values[3] as List<DeviceAlert>,
        firmware: values[4] as FirmwareVersion,
        source: 'api',
      );
    } catch (_) {
      return demoDeviceBundle(deviceId);
    }
  }

  Future<DeviceCommandReceipt> issueCommand(
    String deviceId,
    String command, {
    Map<String, dynamic> parameters = const {},
    bool confirmed = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/devices/$deviceId/commands',
      data: {
        'command': command,
        'parameters': parameters,
        'confirmed': confirmed,
      },
      options: Options(validateStatus: (code) => code == 201 || code == 202),
    );
    return DeviceCommandReceipt.fromJson(response.data ?? {});
  }

  Future<DeviceCommandReceipt> fetchCommand(String commandId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/device-commands/$commandId',
    );
    return DeviceCommandReceipt.fromJson(response.data ?? {});
  }

  Future<List<DeviceAutomationScene>> fetchScenes() async {
    try {
      final response = await _dio.get<List<dynamic>>('/api/v1/device-scenes');
      return (response.data ?? const [])
          .map((item) => DeviceAutomationScene.fromJson(_map(item)))
          .toList(growable: false);
    } catch (_) {
      return demoDeviceScenes;
    }
  }

  Future<DeviceSceneExecution> executeScene(String sceneId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/device-scenes/$sceneId/execute',
    );
    return DeviceSceneExecution.fromJson(response.data ?? {});
  }

  Future<Device> bindDemoDevice({
    required String deviceUid,
    required String name,
    required String deviceType,
    required String sceneRole,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/devices/bind',
      data: {
        'device_uid': deviceUid,
        'name': name,
        'device_type': deviceType,
        'scene_role': sceneRole,
      },
    );
    return Device.fromJson(response.data ?? {});
  }

  Future<void> unbindDevice(String deviceId) async {
    await _dio.delete<void>('/api/v1/devices/$deviceId/binding');
  }

  Future<DeviceCommandReceipt> startFirmwareUpgrade(
    String deviceId, {
    required bool confirmed,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/devices/$deviceId/firmware-upgrades',
      data: {'confirmed': confirmed},
    );
    return DeviceCommandReceipt.fromJson(response.data ?? {});
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}
