import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  static final _client = Supabase.instance.client;

  static Future<UserModel?> getProfile(String userId) async {
    final data = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  static Future<void> updateProfile({
    required String userId,
    String? username,
    String? avatar,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatar != null) updates['avatar'] = avatar;
    if (updates.isNotEmpty) {
      await _client.from('users').update(updates).eq('id', userId);
    }
  }

  static Future<void> addXp(String userId, int xpAmount) async {
    final profile = await getProfile(userId);
    if (profile == null) return;

    final newXp = profile.xp + xpAmount;
    final newLevel = _calculateLevel(newXp);

    await _client
        .from('users')
        .update({'xp': newXp, 'level': newLevel})
        .eq('id', userId);
  }

  static int _calculateLevel(int xp) {
    // Mỗi level cần 1000 XP
    return (xp ~/ 1000) + 1;
  }

  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    final quizCount = await _client
        .from('quiz_results')
        .select()
        .eq('user_id', userId)
        .count(CountOption.exact);

    final simCount = await _client
        .from('simulations')
        .select()
        .eq('user_id', userId)
        .count(CountOption.exact);

    // Calculate rank from users table by XP
    final allUsers = await _client
        .from('users')
        .select('id, xp')
        .order('xp', ascending: false);

    int? bestRank;
    final list = allUsers as List;
    for (int i = 0; i < list.length; i++) {
      if (list[i]['id'] == userId) {
        bestRank = i + 1;
        break;
      }
    }

    return {
      'quizCount': quizCount.count,
      'simulations': simCount.count,
      'bestRank': bestRank,
    };
  }
}
