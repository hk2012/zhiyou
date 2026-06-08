import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session.dart';

class DioClient {
  static late Dio _dio;

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiBaseUrl,
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
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 响应拦截
          return handler.next(response);
        },
        onError: (e, handler) {
          // 错误统一处理
          return handler.next(e);
        },
      ),
    );
  }

  static Dio get instance => _dio;

  static String get baseUrl => _apiBaseUrl;

  static String? resolveAssetUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('/')) return '$_apiBaseUrl$url';

    final uri = Uri.tryParse(url);
    final baseUri = Uri.tryParse(_apiBaseUrl);
    if (uri == null || baseUri == null || !uri.hasScheme) return null;
    if (uri.host == baseUri.host && uri.port == baseUri.port) return url;
    return null;
  }

  static String get _apiBaseUrl {
    const defined = String.fromEnvironment('API_BASE_URL');
    if (defined.isNotEmpty) return defined;

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }
}
