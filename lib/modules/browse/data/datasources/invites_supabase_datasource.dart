import 'package:supabase_flutter/supabase_flutter.dart';

class InvitesSupabaseDatasource {
  final SupabaseClient supabase;
  InvitesSupabaseDatasource({required this.supabase});

  Future<String> inviteUser({
    required String auctionId,
    required String identifier,
    required String type,
  }) async {
    final inviteeId = await _resolveInviteeId(
      identifier: identifier,
      type: type,
    );
    if (inviteeId == null) {
      throw Exception(
        type == 'email'
            ? 'No user found with this email address'
            : 'No user found with this username',
      );
    }

    final res = await supabase.rpc(
      'invite_user_to_auction',
      params: {
        'p_auction_id': auctionId,
        'p_invitee_identifier': identifier,
        'p_identifier_type': type,
      },
    );
    return res as String;
  }

  Future<String?> _resolveInviteeId({
    required String identifier,
    required String type,
  }) async {
    final normalized = identifier.trim();
    if (normalized.isEmpty) {
      return null;
    }

    final query = supabase.from('users').select('id, is_verified');
    final response = type == 'email'
        ? await query.ilike('email', normalized).limit(1).maybeSingle()
        : await query.ilike('username', normalized).limit(1).maybeSingle();

    if (response == null) return null;

    if (response['is_verified'] != true) {
      throw Exception('This user has not completed KYC verification');
    }

    return response['id'] as String?;
  }

  Future<void> respondInvite({
    required String inviteId,
    required String decision,
  }) async {
    await supabase.rpc(
      'respond_to_auction_invite',
      params: {'p_invite_id': inviteId, 'p_decision': decision},
    );
  }

  Future<List<Map<String, dynamic>>> listMyInvites() async {
    final res = await supabase.rpc('list_my_auction_invites');
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<List<Map<String, dynamic>>> getAuctionInvites(String auctionId) async {
    final res = await supabase
        .from('auction_invites')
        .select('*')
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  Future<void> deleteInvite(String inviteId) async {
    await supabase.from('auction_invites').delete().eq('id', inviteId);
  }

  /// Stream real-time invite updates for the current user (as invitee)
  Stream<List<Map<String, dynamic>>> streamMyInvites(String userId) {
    return supabase
        .from('auction_invites')
        .stream(primaryKey: ['id'])
        .eq('invitee_id', userId)
        .order('created_at', ascending: false);
  }

  /// Stream real-time invite updates for a specific auction (for sellers)
  Stream<List<Map<String, dynamic>>> streamAuctionInvites(String auctionId) {
    return supabase
        .from('auction_invites')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);
  }
}
