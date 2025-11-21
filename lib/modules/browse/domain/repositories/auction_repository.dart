import '../entities/auction_entity.dart';

/// Abstract repository for auction operations
/// Defines contract for data layer implementation
abstract class AuctionRepository {
  /// Fetch all active auctions
  Future<List<AuctionEntity>> getActiveAuctions();

  /// Fetch auction by ID
  Future<AuctionEntity?> getAuctionById(String id);

  /// Search auctions by query
  Future<List<AuctionEntity>> searchAuctions(String query);
}
