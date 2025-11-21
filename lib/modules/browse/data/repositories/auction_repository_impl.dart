import '../../domain/entities/auction_entity.dart';
import '../../domain/repositories/auction_repository.dart';
import '../datasources/auction_remote_datasource.dart';

/// Implementation of AuctionRepository
/// Connects domain layer to data source
class AuctionRepositoryImpl implements AuctionRepository {
  final AuctionRemoteDataSource _remoteDataSource;

  AuctionRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<AuctionEntity>> getActiveAuctions() async {
    return await _remoteDataSource.getActiveAuctions();
  }

  @override
  Future<AuctionEntity?> getAuctionById(String id) async {
    return await _remoteDataSource.getAuctionById(id);
  }

  @override
  Future<List<AuctionEntity>> searchAuctions(String query) async {
    return await _remoteDataSource.searchAuctions(query);
  }
}
