import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';

class MysteryTiebreakerDatasource {
  MysteryTiebreakerDatasource._();
  static final MysteryTiebreakerDatasource instance =
      MysteryTiebreakerDatasource._();

  final _client = Supabase.instance.client;

  Future<TiebreakerSessionEntity?> getSession(String auctionId) async {
    try {
      final response = await _client.rpc(
        'get_mystery_tiebreaker_session',
        params: {'p_auction_id': auctionId},
      );
      final json = Map<String, dynamic>.from(response as Map);
      if (json['found'] != true) return null;
      return TiebreakerSessionEntity.fromJson(json);
    } catch (e) {
      debugPrint('[MysteryTiebreakerDatasource] getSession error: $e');
      return null;
    }
  }

  Future<({bool success, String? error, String? action})> setReady(
    String auctionId,
  ) async {
    try {
      final response = await _client.rpc(
        'set_mystery_ready',
        params: {'p_auction_id': auctionId},
      );
      final json = Map<String, dynamic>.from(response as Map);
      return (
        success: json['success'] as bool? ?? false,
        error: json['error'] as String?,
        action: json['action'] as String?,
      );
    } catch (e) {
      return (success: false, error: e.toString(), action: null);
    }
  }

  Future<({bool success, String result, String? error})> submitRpsChoice(
    String auctionId,
    String choice,
  ) async {
    try {
      final response = await _client.rpc(
        'submit_rps_choice',
        params: {'p_auction_id': auctionId, 'p_choice': choice},
      );
      final json = Map<String, dynamic>.from(response as Map);
      return (
        success: json['success'] as bool? ?? false,
        result: json['result'] as String? ?? 'error',
        error: json['error'] as String?,
      );
    } catch (e) {
      return (success: false, result: 'error', error: e.toString());
    }
  }

  Future<Map<String, dynamic>> processTimeout(String auctionId) async {
    try {
      final response = await _client.rpc(
        'process_ready_timeout',
        params: {'p_auction_id': auctionId},
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<List<MysteryParticipantEntity>> getParticipants(
    String auctionId,
  ) async {
    try {
      final response = await _client.rpc(
        'get_mystery_participants',
        params: {'p_auction_id': auctionId},
      );
      final list = List<Map<String, dynamic>>.from(response as List);
      return list
          .map(
            (row) => MysteryParticipantEntity(
              bidderId: row['bidder_id'] as String,
              auctionId: auctionId,
              submittedAt: DateTime.parse(row['submitted_at'] as String),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[MysteryTiebreakerDatasource] getParticipants error: $e');
      return [];
    }
  }

  RealtimeChannel subscribeToSession({
    required String auctionId,
    required VoidCallback onUpdate,
  }) {
    return _client
        .channel('mystery_session:$auctionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'mystery_tiebreaker_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'auction_id',
            value: auctionId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
