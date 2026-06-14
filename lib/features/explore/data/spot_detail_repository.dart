import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'spot_detail_models.dart';

final spotDetailRepositoryProvider = Provider<SpotDetailRepository>((ref) {
  return SpotDetailRepository(DioClient.instance);
});

final spotDetailProvider = FutureProvider.family<SpotDetail, String>((
  ref,
  spotName,
) async {
  return ref.watch(spotDetailRepositoryProvider).fetchByName(spotName);
});

class SpotDetailRepository {
  const SpotDetailRepository(this._dio);

  final Dio _dio;

  Future<SpotDetail> fetchByName(String name) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/explore/spots/lookup',
      queryParameters: {'name': name},
    );
    return SpotDetail.fromJson(response.data ?? {});
  }

  Future<void> favorite(int spotId, {String note = ''}) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/explore/spots/$spotId/favorite',
      data: {'user_id': 1, 'note': note},
    );
  }
}
