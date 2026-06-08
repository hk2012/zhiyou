class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    this.bio,
    this.levelTag,
    this.interests = const [],
  });

  final int id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final String? bio;
  final String? levelTag;
  final List<String> interests;

  factory AppUser.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return AppUser(
      id: map['id'] as int,
      phone: map['phone']?.toString() ?? '',
      nickname: map['nickname']?.toString() ?? '',
      avatarUrl: map['avatarUrl']?.toString(),
      bio: map['bio']?.toString(),
      levelTag: map['levelTag']?.toString(),
      interests:
          (map['interests'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
    );
  }
}

class UserStats {
  const UserStats({
    required this.totalFish,
    required this.spotsExplored,
    required this.daysActive,
    required this.followers,
    required this.following,
  });

  final int totalFish;
  final int spotsExplored;
  final int daysActive;
  final int followers;
  final int following;

  factory UserStats.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return UserStats(
      totalFish: map['totalFish'] as int? ?? 0,
      spotsExplored: map['spotsExplored'] as int? ?? 0,
      daysActive: map['daysActive'] as int? ?? 0,
      followers: map['followers'] as int? ?? 0,
      following: map['following'] as int? ?? 0,
    );
  }
}

class LoginResult {
  const LoginResult({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  final String token;
  final String refreshToken;
  final AppUser user;

  factory LoginResult.fromJson(dynamic json) {
    final map = json as Map<String, dynamic>;
    return LoginResult(
      token: map['token']?.toString() ?? '',
      refreshToken: map['refreshToken']?.toString() ?? '',
      user: AppUser.fromJson(map['user']),
    );
  }
}
