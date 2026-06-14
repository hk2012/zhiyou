import 'package:dio/dio.dart';

enum ApiExceptionKind {
  server,
  unauthorized,
  notFound,
  timeout,
  network,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  ApiException(this.message, {this.code, this.kind = ApiExceptionKind.unknown});

  final String message;
  final int? code;
  final ApiExceptionKind kind;

  factory ApiException.fromDio(DioException error, {required String baseUrl}) {
    final statusCode = error.response?.statusCode;
    final serverMessage = _messageFromResponse(error.response?.data);

    if (statusCode == 401 || statusCode == 403) {
      return ApiException(
        serverMessage ?? '登录状态已失效，请重新登录',
        code: statusCode,
        kind: ApiExceptionKind.unauthorized,
      );
    }

    if (statusCode == 404) {
      return ApiException(
        '接口不存在或后端路由未启动，请检查后端服务和 API 地址',
        code: statusCode,
        kind: ApiExceptionKind.notFound,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        serverMessage ?? '后端服务暂时异常，请稍后再试',
        code: statusCode,
        kind: ApiExceptionKind.server,
      );
    }

    if (statusCode != null) {
      return ApiException(
        serverMessage ?? '请求失败，请稍后再试',
        code: statusCode,
        kind: ApiExceptionKind.server,
      );
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          '连接后端超时，请确认服务已启动：$baseUrl',
          kind: ApiExceptionKind.timeout,
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return ApiException(
          '无法连接后端服务，请检查 API 地址和网络：$baseUrl',
          kind: ApiExceptionKind.network,
        );
      case DioExceptionType.cancel:
        return ApiException('请求已取消', kind: ApiExceptionKind.cancelled);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return ApiException(
          '网络请求失败，请确认后端服务已启动：$baseUrl',
          kind: ApiExceptionKind.network,
        );
    }
  }

  static String? _messageFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    if (data is Map) {
      final message = data['message'] ?? data['detail'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return null;
  }

  @override
  String toString() => message;
}
