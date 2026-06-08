import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession._();

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  static SharedPreferences? _prefs;
  static String? _token;
  static String? _refreshToken;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs?.getString(_tokenKey);
    _refreshToken = _prefs?.getString(_refreshTokenKey);
  }

  static String? get token => _token;
  static String? get refreshToken => _refreshToken;
  static bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  static Future<void> saveTokens({
    required String token,
    required String refreshToken,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_refreshTokenKey, refreshToken);
  }

  static Future<void> clear() async {
    _token = null;
    _refreshToken = null;
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_refreshTokenKey);
  }
}
