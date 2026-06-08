import 'package:dio/dio.dart';

import 'mall_models.dart';

class MallRepository {
  const MallRepository(this._dio);

  final Dio _dio;

  Future<MallSummary> fetchSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/mall/summary',
    );
    return MallSummary.fromJson(response.data ?? {});
  }
}
