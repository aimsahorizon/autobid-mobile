import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesSupabaseDatasource {
  final SupabaseClient supabase;
  UserPreferencesSupabaseDatasource({required this.supabase});

  Future<double?> getBidIncrement({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final res = await supabase
          .from('user_auction_preferences')
          .select('bid_increment')
          .eq('auction_id', auctionId)
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      final n = res['bid_increment'] as num?;
      return n?.toDouble();
    } on PostgrestException catch (e) {
      print('[UserPrefs] getBidIncrement error: ${e.message}');
      return null;
    }
  }

  Future<void> upsertBidIncrement({
    required String auctionId,
    required String userId,
    required double increment,
  }) async {
    try {
      await supabase.from('user_auction_preferences').upsert({
        'auction_id': auctionId,
        'user_id': userId,
        'bid_increment': increment,
      }, onConflict: 'user_id,auction_id');
    } on PostgrestException catch (e) {
      throw Exception('Failed to save preference: ${e.message}');
    }
  }
}
