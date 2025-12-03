import '../entities/auction_entity.dart';
import '../entities/auction_filter.dart';

/// Abstract repository for auction operations
/// Defines contract for data layer implementation
abstract class AuctionRepository {
  /// Fetch all active auctions with optional filtering
  Future<List<AuctionEntity>> getActiveAuctions({AuctionFilter? filter});

  /// Fetch auction by ID
  Future<AuctionEntity?> getAuctionById(String id);

  /// Search auctions by query
  Future<List<AuctionEntity>> searchAuctions(String query);
}
