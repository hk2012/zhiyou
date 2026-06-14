import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'catch_journal_models.dart';

final catchJournalRepositoryProvider = Provider<CatchJournalRepository>((ref) {
  return CatchJournalRepository(DioClient.instance);
});

class CatchJournalRepository {
  const CatchJournalRepository(this._dio);

  final Dio _dio;

  Future<CatchJournalResult> save({
    required String spotName,
    required String fish,
    required String method,
    required String waterClarity,
    required String biteStatus,
    required String deviceStatus,
    required int probability,
    required String title,
    required String shareCopy,
    required String visibility,
    required String status,
    required bool autoLayout,
    required List<String> photoLabels,
    double? lengthCm,
    double? weightJin,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/records/catches',
      data: {
        'user_id': 1,
        'spot_name': spotName,
        'fish': fish,
        'method': method,
        'water_clarity': waterClarity,
        'bite_status': biteStatus,
        'device_status': deviceStatus,
        'probability_at_time': probability,
        'title': title,
        'share_copy': shareCopy,
        'visibility': visibility,
        'status': status,
        'auto_layout': autoLayout,
        'photo_labels': photoLabels,
        'length_cm': lengthCm,
        'weight_kg': weightJin == null ? null : weightJin * 0.5,
        'notes': notes?.trim() ?? '',
      },
    );
    return CatchJournalResult.fromJson(response.data ?? {});
  }
}
