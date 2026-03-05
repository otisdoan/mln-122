import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';

class QuizService {
  static final _client = Supabase.instance.client;

  static Future<List<QuizQuestion>> getQuestions({
    String? difficulty,
    String? topic,
    int limit = 10,
  }) async {
    var query = _client.from('quiz_questions').select();

    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }
    if (topic != null) {
      query = query.eq('topic', topic);
    }

    final data = await query.limit(limit);
    return (data as List).map((e) => QuizQuestion.fromJson(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> getQuizSets({
    String? difficulty,
  }) async {
    var query = _client.from('quiz_sets').select();
    if (difficulty != null) {
      query = query.eq('difficulty', difficulty);
    }
    final data = await query.order('created_at');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<QuizQuestion>> getQuestionsBySet(String setId) async {
    final data = await _client
        .from('quiz_set_questions')
        .select('quiz_questions(*)')
        .eq('set_id', setId);

    return (data as List)
        .map((e) => QuizQuestion.fromJson(e['quiz_questions']))
        .toList();
  }

  static Future<void> saveResult({
    required String userId,
    required int score,
    required int totalQuestions,
    required int timeTakenSeconds,
    String? setId,
  }) async {
    await _client.from('quiz_results').insert({
      'user_id': userId,
      'score': score,
      'total_questions': totalQuestions,
      'time_taken_seconds': timeTakenSeconds,
      'set_id': setId,
    });
  }

  static Future<List<QuizResult>> getUserResults(String userId) async {
    final data = await _client
        .from('quiz_results')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List).map((e) => QuizResult.fromJson(e)).toList();
  }
}
