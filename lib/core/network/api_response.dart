import 'api_exception.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.code,
    required this.message,
    required this.data,
    required this.timestamp,
  });

  final int code;
  final String message;
  final T data;
  final int? timestamp;

  static T parseData<T>(dynamic body, T Function(dynamic json) fromJson) {
    if (body is! Map<String, dynamic>) {
      throw ApiException('接口返回格式异常');
    }

    final code = body['code'] as int?;
    final message = body['message']?.toString() ?? '请求失败';
    if (code != 200) {
      throw ApiException(message, code: code);
    }

    return fromJson(body['data']);
  }
}
