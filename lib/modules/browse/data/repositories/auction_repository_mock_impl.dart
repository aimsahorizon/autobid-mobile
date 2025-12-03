import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_filter.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/auction_mock_datasource.dart';

/// Mock implementation of AuctionRepository for testing
/// Use this instead of AuctionRepositoryImpl for offline development
class AuctionRepositoryMockImpl implements AuctionRepository {
  final AuctionMockDataSource _mockDataSource;

  AuctionRepositoryMockImpl(this._mockDataSource);

  @override
  Future<List<AuctionEntity>> getActiveAuctions({AuctionFilter? filter}) async {
    var auctions = await _mockDataSource.getActiveAuctions();

    // Apply basic client-side filtering for mock data
    if (filter != null) {
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        auctions = auctions.where((auction) {
          return auction.make.toLowerCase().contains(query) ||
                 auction.model.toLowerCase().contains(query);
        }).toList();
      }

      if (filter.make != null && filter.make!.isNotEmpty) {
        auctions = auctions.where((a) => a.make == filter.make).toList();
      }

      if (filter.yearFrom != null) {
        auctions = auctions.where((a) => a.year >= filter.yearFrom!).toList();
      }

      if (filter.yearTo != null) {
        auctions = auctions.where((a) => a.year <= filter.yearTo!).toList();
      }

      if (filter.priceMin != null) {
        auctions = auctions.where((a) => a.currentBid >= filter.priceMin!).toList();
      }

      if (filter.priceMax != null) {
        auctions = auctions.where((a) => a.currentBid <= filter.priceMax!).toList();
      }

      if (filter.endingSoon == true) {
        final twentyFourHoursLater = DateTime.now().add(const Duration(hours: 24));
        auctions = auctions.where((a) => a.endTime.isBefore(twentyFourHoursLater)).toList();
      }
    }

    return auctions;
  }

  @override
  Future<AuctionEntity?> getAuctionById(String id) async {
    return await _mockDataSource.getAuctionById(id);
  }

  @override
  Future<List<AuctionEntity>> searchAuctions(String query) async {
    return await _mockDataSource.searchAuctions(query);
  }
}
