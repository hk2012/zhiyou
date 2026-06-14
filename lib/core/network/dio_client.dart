import 'package:dio/dio.dart';

import '../auth/auth_session.dart';
import 'api_environment.dart';
import 'api_exception.dart';

class DioClient {
  static late Dio _dio;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEnvironment.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 添加通用的拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = AuthSession.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['X-Client-Api-Env'] = ApiEnvironment.profileLabel;
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 响应拦截
          return handler.next(response);
        },
        onError: (error, handler) {
          final exception = ApiException.fromDio(
            error,
            baseUrl: ApiEnvironment.baseUrl,
          );
          error.requestOptions.extra['friendly_message'] = exception.message;
          return handler.reject(error.copyWith(error: exception));
        },
      ),
    );
  }

  static Dio get instance => _dio;

  static String get baseUrl => ApiEnvironment.baseUrl;

  static String get environmentSummary => ApiEnvironment.debugSummary;

  static String friendlyErrorMessage(DioException error) {
    final inner = error.error;
    if (inner is ApiException) return inner.message;
    final message = error.requestOptions.extra['friendly_message'];
    if (message != null && message.toString().isNotEmpty) {
      return message.toString();
    }
    return ApiException.fromDio(error, baseUrl: ApiEnvironment.baseUrl).message;
  }

  static String? resolveAssetUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/')) return '${ApiEnvironment.baseUrl}$url';

    final uri = Uri.tryParse(url);
    final baseUri = Uri.tryParse(ApiEnvironment.baseUrl);
    if (uri == null || baseUri == null || !uri.hasScheme) return null;
    if (uri.host == baseUri.host && uri.port == baseUri.port) return url;
    return null;
  }
}
