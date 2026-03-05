import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/leaderboard_entry.dart';

class LeaderboardService {
  static final _client = Supabase.instance.client;

  static Future<List<LeaderboardEntry>> getLeaderboard({
    String sortBy = 'xp',
    int limit = 50,
  }) async {
    final data = await _client
        .from('users')
        .select('id, username, avatar, xp, level')
        .order(sortBy, ascending: false)
        .limit(limit);

    return (data as List).asMap().entries.map((entry) {
      final e = entry.value;
      return LeaderboardEntry(
        userId: e['id'],
        username: e['username'] ?? 'Unknown',
        avatar: e['avatar'] ?? '',
        score: e['xp'] ?? 0,
        rank: entry.key + 1,
        season: sortBy,
      );
    }).toList();
  }
}
