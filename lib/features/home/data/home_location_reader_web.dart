// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'home_recommendation_models.dart';

Future<HomeLocation?> readDeviceLocation() async {
  try {
    // 先查询已有授权状态，避免弹出授权弹窗阻塞 UI
    final permissionStatus = await _queryPermission();
    // 仅在已明确授权时才请求位置，拒绝/待定状态立即返回 null
    if (permissionStatus != 'granted') return null;

    final position = await html.window.navigator.geolocation
        .getCurrentPosition(enableHighAccuracy: false)
        .timeout(const Duration(seconds: 3));
    final coords = position.coords;
    final latitude = coords?.latitude;
    final longitude = coords?.longitude;
    if (latitude == null || longitude == null) return null;

    return HomeLocation(
      name: '浏览器定位附近水域',
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      source: 'device',
      statusMessage: '已获取浏览器定位',
      accuracyMeters: coords?.accuracy?.toDouble(),
    );
  } catch (_) {
    // 任何异常（超时、拒绝、不支持）都静默返回 null，不阻塞 UI
    return null;
  }
}

/// 查询 geolocation 权限状态，不触发授权弹窗
Future<String> _queryPermission() async {
  try {
    final permissions = html.window.navigator.permissions;
    if (permissions == null) return 'prompt';
    final result = await permissions.query({'name': 'geolocation'});
    return result.state ?? 'prompt';
  } catch (_) {
    return 'prompt';
  }
}

