import '../../domain/entities/bid_history_entity.dart';

/// Mock data source for bid history
/// Provides sample bid data for development and testing
/// Replace with real Supabase implementation in production
class BidHistoryMockDataSource {
  /// Simulates fetching bid history from backend
  /// Returns list of bids sorted by timestamp (newest first)
  Future<List<BidHistoryEntity>> getBidHistory(String auctionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    // Generate mock bid history data
    return [
      BidHistoryEntity(
        id: 'bid_001',
        auctionId: auctionId,
        bidderName: 'You',
        amount: 485000,
        timestamp: now.subtract(const Duration(minutes: 5)),
        isCurrentUser: true,
        isWinning: true,
      ),
      BidHistoryEntity(
        id: 'bid_002',
        auctionId: auctionId,
        bidderName: 'Bidder #42',
        amount: 480000,
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      BidHistoryEntity(
        id: 'bid_003',
        auctionId: auctionId,
        bidderName: 'Bidder #28',
        amount: 475000,
        timestamp: now.subtract(const Duration(minutes: 45)),
      ),
      BidHistoryEntity(
        id: 'bid_004',
        auctionId: auctionId,
        bidderName: 'You',
        amount: 470000,
        timestamp: now.subtract(const Duration(hours: 1)),
        isCurrentUser: true,
      ),
      BidHistoryEntity(
        id: 'bid_005',
        auctionId: auctionId,
        bidderName: 'Bidder #15',
        amount: 465000,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      BidHistoryEntity(
        id: 'bid_006',
        auctionId: auctionId,
        bidderName: 'Bidder #42',
        amount: 460000,
        timestamp: now.subtract(const Duration(hours: 3)),
      ),
      BidHistoryEntity(
        id: 'bid_007',
        auctionId: auctionId,
        bidderName: 'Bidder #7',
        amount: 455000,
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      BidHistoryEntity(
        id: 'bid_008',
        auctionId: auctionId,
        bidderName: 'Bidder #33',
        amount: 450000,
        timestamp: now.subtract(const Duration(hours: 8)),
      ),
    ];
  }
}
