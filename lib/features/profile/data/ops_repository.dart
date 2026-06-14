import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'ops_models.dart';

final opsRepositoryProvider = Provider<OpsRepository>((ref) {
  return OpsRepository(DioClient.instance);
});

final opsOverviewProvider = FutureProvider<OpsOverview>((ref) async {
  return ref.watch(opsRepositoryProvider).fetchOverview();
});

final opsMonitoringProvider = FutureProvider<OpsMonitoring>((ref) async {
  return ref.watch(opsRepositoryProvider).fetchMonitoring();
});

class OpsRepository {
  const OpsRepository(this._dio);

  final Dio _dio;

  Future<OpsOverview> fetchOverview() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/ops/overview',
      );
      return OpsOverview.fromJson(response.data ?? {});
    } on DioException {
      return OpsOverview.fallback();
    }
  }

  Future<OpsMonitoring> fetchMonitoring() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/ops/monitoring',
      );
      return OpsMonitoring.fromJson(response.data ?? {});
    } on DioException {
      return OpsMonitoring.fallback();
    }
  }
}
