import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'community_models.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(DioClient.instance);
});

class CommunityRepository {
  const CommunityRepository(this._dio);

  final Dio _dio;

  Future<List<CommunityPost>> fetchFeed() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/records/catches',
        queryParameters: {'limit': 20},
      );
      final items = response.data?['items'] as List<dynamic>? ?? [];
      return items.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
