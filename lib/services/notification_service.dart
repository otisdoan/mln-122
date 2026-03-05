import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _client = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getNotifications(
    String userId,
  ) async {
    final data = await _client
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<int> getUnreadCount(String userId) async {
    final data = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (data as List).length;
  }

  static Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  static Future<void> markAllAsRead(String userId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  static Future<void> createNotification({
    required String userId,
    required String title,
    String message = '',
    String type = 'info',
  }) async {
    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'is_read': false,
    });
  }
}
