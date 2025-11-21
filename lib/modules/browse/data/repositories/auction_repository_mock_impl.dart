import '../../domain/entities/auction_entity.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/auction_mock_datasource.dart';

/// Mock implementation of AuctionRepository for testing
/// Use this instead of AuctionRepositoryImpl for offline development
class AuctionRepositoryMockImpl implements AuctionRepository {
  final AuctionMockDataSource _mockDataSource;

  AuctionRepositoryMockImpl(this._mockDataSource);

  @override
  Future<List<AuctionEntity>> getActiveAuctions() async {
    return await _mockDataSource.getActiveAuctions();
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
