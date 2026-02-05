import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_filter.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/auction_supabase_datasource.dart';

/// Supabase implementation of AuctionRepository
class AuctionRepositorySupabaseImpl implements AuctionRepository {
  final AuctionSupabaseDataSource _supabaseDataSource;
  final NetworkInfo _networkInfo;

  AuctionRepositorySupabaseImpl(this._supabaseDataSource, this._networkInfo);

  @override
  Future<List<AuctionEntity>> getActiveAuctions({AuctionFilter? filter}) async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    try {
      final models = await _supabaseDataSource.getActiveAuctions(filter: filter);
      return models;
    } catch (e) {
      throw Exception('Failed to get active auctions: $e');
    }
  }

  @override
  Future<AuctionEntity?> getAuctionById(String id) async {
    if (!await _networkInfo.isConnected) {
      // Allow returning null if offline? Or throw?
      // Since it's detail view, throw is better to prevent navigating to empty page
      throw Exception('No internet connection');
    }
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
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }
    try {
      final filter = AuctionFilter(searchQuery: query);
      final models = await _supabaseDataSource.getActiveAuctions(filter: filter);
      return models;
    } catch (e) {
      throw Exception('Failed to search auctions: $e');
    }
  }

  @override
  Stream<void> streamActiveAuctions() {
    return _supabaseDataSource.streamAuctionsTable();
  }
}
