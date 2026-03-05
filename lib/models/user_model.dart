class UserModel {
  final String id;
  final String email;
  final String username;
  final String avatar;
  final int xp;
  final int level;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.avatar = '',
    this.xp = 0,
    this.level = 1,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'avatar': avatar,
      'xp': xp,
      'level': level,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get levelTitle {
    if (level >= 15) return 'Nhà Kinh tế học';
    if (level >= 10) return 'Chuyên gia';
    if (level >= 5) return 'Học viên ưu tú';
    return 'Người mới';
  }
}
