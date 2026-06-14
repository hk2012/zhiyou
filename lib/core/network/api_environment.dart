import 'package:flutter/foundation.dart';

enum ApiEnvironmentKind { auto, local, web, simulator, device }

class ApiEnvironment {
  ApiEnvironment._();

  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _definedKind = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'auto',
  );

  static const String localBaseUrl = 'http://127.0.0.1:8080';
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8080';

  static ApiEnvironmentKind get kind => _parseKind(_definedKind);

  static String get baseUrl {
    final normalized = _normalizeBaseUrl(_definedBaseUrl);
    if (normalized.isNotEmpty) return normalized;
    return _defaultBaseUrl(kind);
  }

  static String get profileLabel {
    return switch (kind) {
      ApiEnvironmentKind.auto => 'auto',
      ApiEnvironmentKind.local => 'local',
      ApiEnvironmentKind.web => 'web',
      ApiEnvironmentKind.simulator => 'simulator',
      ApiEnvironmentKind.device => 'device',
    };
  }

  static String get healthUrl => '$baseUrl/api/v1/health';

  static bool get usesExplicitBaseUrl => _definedBaseUrl.trim().isNotEmpty;

  static bool get shouldWarnForDeviceBaseUrl {
    return kind == ApiEnvironmentKind.device && !usesExplicitBaseUrl;
  }

  static String get debugSummary {
    return 'API_ENV=$profileLabel, API_BASE_URL=$baseUrl';
  }

  static ApiEnvironmentKind _parseKind(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'local' => ApiEnvironmentKind.local,
      'web' => ApiEnvironmentKind.web,
      'simulator' || 'emulator' => ApiEnvironmentKind.simulator,
      'device' || 'phone' || 'real_device' => ApiEnvironmentKind.device,
      _ => ApiEnvironmentKind.auto,
    };
  }

  static String _defaultBaseUrl(ApiEnvironmentKind kind) {
    return switch (kind) {
      ApiEnvironmentKind.web => localBaseUrl,
      ApiEnvironmentKind.local => localBaseUrl,
      ApiEnvironmentKind.simulator => _simulatorBaseUrl(),
      ApiEnvironmentKind.device => localBaseUrl,
      ApiEnvironmentKind.auto => _autoBaseUrl(),
    };
  }

  static String _autoBaseUrl() {
    if (kIsWeb) return localBaseUrl;
    return _simulatorBaseUrl();
  }

  static String _simulatorBaseUrl() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return androidEmulatorBaseUrl;
    }
    return localBaseUrl;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
