import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'device_models.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(DioClient.instance);
});

class DeviceRepository {
  const DeviceRepository(this._dio);

  final Dio _dio;

  Future<DeviceListResult> fetchDevices({int userId = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/devices',
      queryParameters: {'user_id': userId},
    );
    return DeviceListResult.fromJson(response.data ?? {});
  }

  Future<Device> fetchDevice(String deviceId, {int userId = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/devices/$deviceId',
      queryParameters: {'user_id': userId},
    );
    return Device.fromJson(response.data ?? {});
  }

  Future<List<DeviceTelemetry>> fetchTelemetry(
    String deviceId, {
    int userId = 1,
    int limit = 24,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/devices/$deviceId/telemetry',
      queryParameters: {'user_id': userId, 'limit': limit},
    );
    final rows = response.data ?? const [];
    return rows
        .map((item) => DeviceTelemetry.fromJson(_asResponseMap(item)))
        .toList(growable: false);
  }

  Future<List<DeviceAlert>> fetchAlerts(
    String deviceId, {
    int userId = 1,
    bool includeResolved = false,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/v1/devices/$deviceId/alerts',
      queryParameters: {'user_id': userId, 'include_resolved': includeResolved},
    );
    final rows = response.data ?? const [];
    return rows
        .map((item) => DeviceAlert.fromJson(_asResponseMap(item)))
        .toList(growable: false);
  }

  Future<FirmwareVersion> fetchFirmware(
    String deviceId, {
    int userId = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/devices/$deviceId/firmware',
      queryParameters: {'user_id': userId},
    );
    return FirmwareVersion.fromJson(response.data ?? {});
  }
}

Map<String, dynamic> _asResponseMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return <String, dynamic>{};
}
