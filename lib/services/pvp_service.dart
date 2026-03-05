import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_question.dart';
import 'notification_service.dart';

class PvpService {
  static final _client = Supabase.instance.client;

  /// Create a new PvP room
  static Future<Map<String, dynamic>> createRoom(String hostId) async {
    final data = await _client
        .from('pvp_rooms')
        .insert({'host_id': hostId, 'status': 'waiting'})
        .select()
        .single();
    return data;
  }

  /// Send invitation to a user by username
  static Future<bool> sendInvite({
    required String roomId,
    required String hostUsername,
    required String guestUsername,
  }) async {
    // Find the guest user by username
    final users = await _client
        .from('users')
        .select('id, username')
        .eq('username', guestUsername)
        .limit(1);

    if ((users as List).isEmpty) return false;

    final guestId = users[0]['id'] as String;

    // Update room with guest_id
    await _client
        .from('pvp_rooms')
        .update({'guest_id': guestId})
        .eq('id', roomId);

    // Send notification to guest
    await NotificationService.createNotification(
      userId: guestId,
      title: '🎮 Lời mời PvP từ $hostUsername',
      message: roomId,
      type: 'pvp_invite',
    );

    return true;
  }

  /// Accept invitation — update room status to 'accepted'
  static Future<void> acceptInvite(String roomId) async {
    await _client
        .from('pvp_rooms')
        .update({'status': 'accepted'})
        .eq('id', roomId);
  }

  /// Set player as ready
  static Future<void> setReady(String roomId, String userId) async {
    final room = await _client
        .from('pvp_rooms')
        .select()
        .eq('id', roomId)
        .single();
    if (room['host_id'] == userId) {
      await _client
          .from('pvp_rooms')
          .update({'host_ready': true})
          .eq('id', roomId);
    } else {
      await _client
          .from('pvp_rooms')
          .update({'guest_ready': true})
          .eq('id', roomId);
    }
  }

  /// Start the game — load questions, set status to 'playing'
  static Future<List<QuizQuestion>> startGame(String roomId) async {
    // Get random questions
    final questionsData = await _client
        .from('quiz_questions')
        .select()
        .limit(10);

    final questions = (questionsData as List)
        .map((e) => QuizQuestion.fromJson(e))
        .toList();
    questions.shuffle();
    final selected = questions.take(10).toList();

    // Save room questions
    for (int i = 0; i < selected.length; i++) {
      await _client.from('pvp_room_questions').insert({
        'room_id': roomId,
        'question_id': selected[i].id,
        'question_index': i,
      });
    }

    // Update room status
    await _client
        .from('pvp_rooms')
        .update({
          'status': 'playing',
          'started_at': DateTime.now().toUtc().toIso8601String(),
          'total_questions': selected.length,
          'current_question': 0,
        })
        .eq('id', roomId);

    return selected;
  }

  /// Get room questions (for the guest who joins after host started)
  static Future<List<QuizQuestion>> getRoomQuestions(String roomId) async {
    final data = await _client
        .from('pvp_room_questions')
        .select('question_index, quiz_questions(*)')
        .eq('room_id', roomId)
        .order('question_index');

    return (data as List)
        .map((e) => QuizQuestion.fromJson(e['quiz_questions']))
        .toList();
  }

  /// Submit an answer
  static Future<bool> submitAnswer({
    required String roomId,
    required String userId,
    required String questionId,
    required int questionIndex,
    required String answer,
    required String correctAnswer,
  }) async {
    final isCorrect = answer == correctAnswer;

    await _client.from('pvp_answers').insert({
      'room_id': roomId,
      'user_id': userId,
      'question_id': questionId,
      'question_index': questionIndex,
      'answer': answer,
      'is_correct': isCorrect,
    });

    // Update score in room
    final room = await _client
        .from('pvp_rooms')
        .select()
        .eq('id', roomId)
        .single();
    final isHost = room['host_id'] == userId;
    final scoreField = isHost ? 'host_score' : 'guest_score';
    final currentScore = room[scoreField] as int? ?? 0;
    final delta = isCorrect ? 100 : -30;
    final newScore = (currentScore + delta).clamp(0, 999999);

    await _client
        .from('pvp_rooms')
        .update({scoreField: newScore})
        .eq('id', roomId);

    return isCorrect;
  }

  /// Advance to next question (host controls this)
  static Future<void> advanceQuestion(String roomId, int nextIndex) async {
    await _client
        .from('pvp_rooms')
        .update({'current_question': nextIndex})
        .eq('id', roomId);
  }

  /// Finish the game
  static Future<Map<String, dynamic>> finishGame(String roomId) async {
    final room = await _client
        .from('pvp_rooms')
        .select()
        .eq('id', roomId)
        .single();

    final hostScore = room['host_score'] as int? ?? 0;
    final guestScore = room['guest_score'] as int? ?? 0;
    String? winnerId;
    if (hostScore > guestScore) {
      winnerId = room['host_id'];
    } else if (guestScore > hostScore) {
      winnerId = room['guest_id'];
    }

    await _client
        .from('pvp_rooms')
        .update({
          'status': 'finished',
          'winner_id': winnerId,
          'finished_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', roomId);

    return {
      'host_score': hostScore,
      'guest_score': guestScore,
      'winner_id': winnerId,
      'host_id': room['host_id'],
      'guest_id': room['guest_id'],
    };
  }

  /// Get room data
  static Future<Map<String, dynamic>> getRoom(String roomId) async {
    return await _client.from('pvp_rooms').select().eq('id', roomId).single();
  }

  /// Subscribe to room changes (Realtime)
  static RealtimeChannel subscribeToRoom(
    String roomId,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    return _client
        .channel('pvp_room_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pvp_rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            onUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from room
  static void unsubscribeFromRoom(RealtimeChannel channel) {
    _client.removeChannel(channel);
  }
}
