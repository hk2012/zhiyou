import 'dart:async';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'home_recommendation_models.dart';

Future<HomeLocation?> readDeviceLocation() async {
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  // 用户拒绝或永久拒绝时，不打断首页流程，回退到默认钓点继续推荐。
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  final position = await _readCurrentOrLastKnownPosition();
  if (position == null) return null;
  final addressName = await _resolveChineseAddress(
    position.latitude,
    position.longitude,
  );

  return HomeLocation(
    name: addressName,
    latitude: position.latitude,
    longitude: position.longitude,
    source: 'device',
    statusMessage: '已获取系统定位，并完成中文地址解析',
    accuracyMeters: position.accuracy,
  );
}

Future<Position?> _readCurrentOrLastKnownPosition() async {
  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  } on TimeoutException {
    return Geolocator.getLastKnownPosition();
  } catch (_) {
    return Geolocator.getLastKnownPosition();
  }
}

Future<String> _resolveChineseAddress(double latitude, double longitude) async {
  try {
    await setLocaleIdentifier('zh_CN');
    final placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    ).timeout(const Duration(seconds: 5));
    if (placemarks.isEmpty) return '当前位置附近水域';

    final place = placemarks.first;
    final parts =
        [
              place.administrativeArea,
              place.locality,
              place.subLocality,
              place.thoroughfare,
              place.name,
            ]
            .whereType<String>()
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
    if (parts.isEmpty) return '当前位置附近水域';
    return parts.take(4).join(' · ');
  } catch (_) {
    return '当前位置附近水域';
  }
}
