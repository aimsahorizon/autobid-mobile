import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsSupabaseDatasource {
  final SupabaseClient supabase;
  NotificationsSupabaseDatasource({required this.supabase});

  Future<List<Map<String, dynamic>>> listMyNotifications() async {
    final res = await supabase
        .from('notifications')
        .select(
          'id, type_id, title, message, data, created_at, is_read, notification_types(type_name)',
        )
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> markRead(String notificationId) async {
    await supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<int> getUnreadCount() async {
    final res = await supabase
        .from('notifications')
        .select('id')
        .eq('is_read', false);
    return (res as List).length;
  }
}
