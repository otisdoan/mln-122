class LeaderboardEntry {
  final String userId;
  final String username;
  final String avatar;
  final int score;
  final int rank;
  final String season;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatar = '',
    required this.score,
    required this.rank,
    this.season = 'daily',
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {int rank = 0}) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      avatar: json['avatar'] as String? ?? '',
      score: json['score'] as int? ?? 0,
      rank: rank,
      season: json['season'] as String? ?? 'daily',
    );
  }
}
