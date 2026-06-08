import 'auth_models.dart';

class DemoAuthData {
  DemoAuthData._();

  static const demoPhone = '13800000000';
  static const demoPassword = '123456';
  static const demoToken = 'demo-access-token';
  static const demoRefreshToken = 'demo-refresh-token';

  static const AppUser _seedUser = AppUser(
    id: 1,
    phone: demoPhone,
    nickname: '江湖钓客演示用户',
    avatarUrl: 'https://example.com/avatar/demo-user.png',
    bio: '喜欢路亚和台钓，正在记录每一次出钓。',
    levelTag: '新手钓友',
    interests: ['路亚', '台钓'],
  );

  static const UserStats _seedStats = UserStats(
    totalFish: 18,
    spotsExplored: 6,
    daysActive: 12,
    followers: 32,
    following: 15,
  );

  static AppUser _currentUser = _seedUser;
  static UserStats _currentStats = _seedStats;

  static bool matchesCredentials(String phone, String password) {
    return phone == demoPhone && password == demoPassword;
  }

  static bool isDemoToken(String? token) => token == demoToken;

  static void reset() {
    _currentUser = _seedUser;
    _currentStats = _seedStats;
  }

  static LoginResult buildLoginResult() {
    return LoginResult(
      token: demoToken,
      refreshToken: demoRefreshToken,
      user: _currentUser,
    );
  }

  static AppUser currentUser() => _currentUser;
  static UserStats currentStats() => _currentStats;

  static AppUser updateCurrentUser({
    required String nickname,
    required String bio,
    required List<String> interests,
  }) {
    _currentUser = AppUser(
      id: _currentUser.id,
      phone: _currentUser.phone,
      nickname: nickname,
      avatarUrl: _currentUser.avatarUrl,
      bio: bio,
      levelTag: _currentUser.levelTag,
      interests: interests,
    );
    return _currentUser;
  }

  static String updateAvatar() {
    return _currentUser.avatarUrl ?? '';
  }
}
