import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';

class AchievementService {
  static final _client = Supabase.instance.client;

  static Future<List<Achievement>> getAllAchievements() async {
    final data = await _client.from('achievements').select().order('id');

    return (data as List).map((e) => Achievement.fromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserAchievements(
    String userId,
  ) async {
    final data = await _client
        .from('user_achievements')
        .select('*, achievements(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Achievement>> getAchievementsWithProgress(
    String userId,
  ) async {
    final allAchievements = await getAllAchievements();
    final userAchievements = await getUserAchievements(userId);

    final progressMap = <String, Map<String, dynamic>>{};
    for (final ua in userAchievements) {
      progressMap[ua['achievement_id'].toString()] = ua;
    }

    return allAchievements.map((a) {
      final ua = progressMap[a.id];
      if (ua != null) {
        return Achievement(
          id: a.id,
          title: a.title,
          description: a.description,
          icon: a.icon,
          progress: (ua['progress'] as num).toDouble(),
          isUnlocked: ua['unlocked'] == true,
        );
      }
      return a;
    }).toList();
  }

  static Future<void> updateProgress({
    required String userId,
    required String achievementId,
    required double progress,
  }) async {
    final unlocked = progress >= 1.0;
    await _client.from('user_achievements').upsert({
      'user_id': userId,
      'achievement_id': achievementId,
      'progress': progress,
      'unlocked': unlocked,
    }, onConflict: 'user_id,achievement_id');
  }
}
