import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_session.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'demo_auth_data.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(DioClient.instance);
});

final currentUserProvider = FutureProvider<AppUser>((ref) async {
  return ref.watch(authRepositoryProvider).fetchCurrentUser();
});

final userStatsProvider = FutureProvider<UserStats>((ref) async {
  return ref.watch(authRepositoryProvider).fetchCurrentUserStats();
});

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  Future<LoginResult> loginWithPassword({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/login/password',
        data: {'phone': phone, 'password': password},
      );
      final result = ApiResponse.parseData(response.data, LoginResult.fromJson);

      await AuthSession.saveTokens(
        token: result.token,
        refreshToken: result.refreshToken,
      );
      return result;
    } on DioException catch (error) {
      if (_shouldUseDemoFallback(error, phone, password)) {
        DemoAuthData.reset();
        final result = DemoAuthData.buildLoginResult();
        await AuthSession.saveTokens(
          token: result.token,
          refreshToken: result.refreshToken,
        );
        return result;
      }
      rethrow;
    }
  }

  Future<AppUser> fetchCurrentUser() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/v1/user/me');
      return ApiResponse.parseData(response.data, AppUser.fromJson);
    } on DioException catch (error) {
      if (_shouldUseDemoFallback(error)) {
        return DemoAuthData.currentUser();
      }
      rethrow;
    }
  }

  Future<AppUser> updateCurrentUser({
    required String nickname,
    required String bio,
    required List<String> interests,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/user/me',
        data: {'nickname': nickname, 'bio': bio, 'interests': interests},
      );
      return ApiResponse.parseData(response.data, AppUser.fromJson);
    } on DioException catch (error) {
      if (_shouldUseDemoFallback(error)) {
        return DemoAuthData.updateCurrentUser(
          nickname: nickname,
          bio: bio,
          interests: interests,
        );
      }
      rethrow;
    }
  }

  Future<UserStats> fetchCurrentUserStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/user/me/stats',
      );
      return ApiResponse.parseData(response.data, UserStats.fromJson);
    } on DioException catch (error) {
      if (_shouldUseDemoFallback(error)) {
        return DemoAuthData.currentStats();
      }
      rethrow;
    }
  }

  Future<String> uploadAvatar(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/user/avatar',
        data: formData,
      );
      return ApiResponse.parseData(
        response.data,
        (json) => (json as Map<String, dynamic>)['url']?.toString() ?? '',
      );
    } on DioException catch (error) {
      if (_shouldUseDemoFallback(error)) {
        return DemoAuthData.updateAvatar();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<Map<String, dynamic>>('/api/v1/auth/logout');
    } finally {
      await AuthSession.clear();
      DemoAuthData.reset();
    }
  }

  bool _shouldUseDemoFallback(
    DioException error, [
    String? phone,
    String? password,
  ]) {
    final isNetworkLayerError = error.response == null;
    if (!isNetworkLayerError) return false;
    if (phone == null || password == null) {
      return DemoAuthData.isDemoToken(AuthSession.token);
    }
    return DemoAuthData.matchesCredentials(phone, password);
  }
}
