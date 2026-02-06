import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_datasource.dart';
import '../models/notification_model.dart';

/// Supabase data source for notifications
class NotificationSupabaseDataSource implements INotificationDataSource {
  final SupabaseClient supabase;

  NotificationSupabaseDataSource({required this.supabase});

  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    var query = supabase
        .from('notifications')
        .select('''
          *,
          type:notification_types(type_name)
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 20) - 1);
    }

    final response = await query;
    return (response as List).map((json) {
      // Flatten the joined type name
      final Map<String, dynamic> data = Map<String, dynamic>.from(json);
      if (json['type'] != null && json['type'] is Map) {
        data['type'] = json['type']['type_name'];
      }
      return NotificationModel.fromJson(data);
    }).toList();
  }

  @override
  Future<int> getUnreadCount({required String userId}) async {
    final response = await supabase.rpc('get_unread_count');
    return response as int;
  }

  @override
  Future<void> markAsRead({required String notificationId}) async {
    await supabase.rpc(
      'mark_notification_read',
      params: {'p_notification_id': notificationId},
    );
  }

  @override
  Future<int> markAllAsRead() async {
    final response = await supabase.rpc('mark_all_notifications_read');
    return response as int;
  }

  @override
  Future<void> deleteNotification({required String notificationId}) async {
    await supabase.rpc(
      'delete_notification',
      params: {'p_notification_id': notificationId},
    );
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications({
    required String userId,
  }) async {
    final response = await supabase
        .from('notifications')
        .select('''
          *,
          type:notification_types(type_name)
        ''')
        .eq('user_id', userId)
        .eq('is_read', false)
        .order('created_at', ascending: false);

    return (response as List).map((json) {
      // Flatten the joined type name
      final Map<String, dynamic> data = Map<String, dynamic>.from(json);
      if (json['type'] != null && json['type'] is Map) {
        data['type'] = json['type']['type_name'];
      }
      return NotificationModel.fromJson(data);
    }).toList();
  }

  @override
  Future<void> respondToInvite({
    required String inviteId,
    required String decision,
  }) async {
    await supabase.rpc('respond_to_auction_invite', params: {
      'p_invite_id': inviteId,
      'p_decision': decision,
    });
  }
}
