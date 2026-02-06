import 'package:supabase_flutter/supabase_flutter.dart';

class InvitesSupabaseDatasource {
  final SupabaseClient supabase;
  InvitesSupabaseDatasource({required this.supabase});

  Future<String> inviteUser({
    required String auctionId,
    required String identifier,
    required String type,
  }) async {
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
}
