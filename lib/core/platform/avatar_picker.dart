import 'package:flutter/services.dart';

class AvatarPicker {
  AvatarPicker._();

  static const _channel = MethodChannel('zhiyou/avatar_picker');

  static Future<String?> pickImagePath() async {
    final path = await _channel.invokeMethod<String>('pickImage');
    if (path == null || path.isEmpty) return null;
    return path;
  }
}
