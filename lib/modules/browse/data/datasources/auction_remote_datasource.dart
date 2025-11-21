import '../../../../app/core/services/supabase_service.dart';
import '../models/auction_model.dart';

/// Remote data source for auctions using Supabase
class AuctionRemoteDataSource {
  final SupabaseService _supabaseService;

  AuctionRemoteDataSource(this._supabaseService);

  /// Fetch all active auctions from Supabase
  /// Filters by end_time > now and orders by end_time ascending
  Future<List<AuctionModel>> getActiveAuctions() async {
    try {
      final response = await _supabaseService.client
          .from('auctions')
          .select()
          .gt('end_time', DateTime.now().toIso8601String())
          .order('end_time', ascending: true);

      return (response as List)
          .map((json) => AuctionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch auctions: $e');
    }
  }

  /// Fetch single auction by ID
  Future<AuctionModel?> getAuctionById(String id) async {
    try {
      final response = await _supabaseService.client
          .from('auctions')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return AuctionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch auction: $e');
    }
  }

  /// Search auctions by make or model
  Future<List<AuctionModel>> searchAuctions(String query) async {
    try {
      final response = await _supabaseService.client
          .from('auctions')
          .select()
          .or('make.ilike.%$query%,model.ilike.%$query%')
          .gt('end_time', DateTime.now().toIso8601String())
          .order('end_time', ascending: true);

      return (response as List)
          .map((json) => AuctionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search auctions: $e');
    }
  }
}
