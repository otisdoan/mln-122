import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lesson.dart';

class LessonService {
  static final _client = Supabase.instance.client;

  static Future<List<Lesson>> getLessons() async {
    final data = await _client.from('lessons').select().order('order_index');

    final all = (data as List).map((e) => Lesson.fromJson(e)).toList();
    // Deduplicate by title, keeping first occurrence
    final seen = <String>{};
    return all.where((l) => seen.add(l.title)).toList();
  }

  static Future<Lesson?> getLessonById(String id) async {
    final data = await _client
        .from('lessons')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Lesson.fromJson(data);
  }

  static Future<void> markLessonComplete({
    required String userId,
    required String lessonId,
  }) async {
    await _client.from('user_lessons').upsert({
      'user_id': userId,
      'lesson_id': lessonId,
      'completed': true,
      'completed_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,lesson_id');
  }

  static Future<List<String>> getCompletedLessonIds(String userId) async {
    final data = await _client
        .from('user_lessons')
        .select('lesson_id')
        .eq('user_id', userId)
        .eq('completed', true);

    return (data as List).map((e) => e['lesson_id'].toString()).toList();
  }
}
