import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_filter.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/auction_supabase_datasource.dart';

/// Supabase implementation of AuctionRepository
class AuctionRepositorySupabaseImpl implements AuctionRepository {
  final AuctionSupabaseDataSource _supabaseDataSource;

  AuctionRepositorySupabaseImpl(this._supabaseDataSource);

  @override
  Future<List<AuctionEntity>> getActiveAuctions({AuctionFilter? filter}) async {
    try {
      final models = await _supabaseDataSource.getActiveAuctions(filter: filter);
      return models;
    } catch (e) {
      throw Exception('Failed to get active auctions: $e');
    }
  }

  @override
  Future<AuctionEntity?> getAuctionById(String id) async {
    try {
      final models = await _supabaseDataSource.getActiveAuctions();
      final model = models.firstWhere((m) => m.id == id);
      return model;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<AuctionEntity>> searchAuctions(String query) async {
    try {
      final filter = AuctionFilter(searchQuery: query);
      final models = await _supabaseDataSource.getActiveAuctions(filter: filter);
      return models;
    } catch (e) {
      throw Exception('Failed to search auctions: $e');
    }
  }
}
