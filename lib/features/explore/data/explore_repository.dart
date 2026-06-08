import 'package:dio/dio.dart';

import 'explore_models.dart';

class ExploreRepository {
  const ExploreRepository(this._dio);

  final Dio _dio;

  Future<ExploreSummary> fetchSummary({required String layerKey}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/explore/summary',
      queryParameters: {'layer_key': layerKey},
    );
    return ExploreSummary.fromJson(response.data ?? {});
  }
}
