import '../../app/core/services/supabase_service.dart';
import 'data/datasources/auction_mock_datasource.dart';
import 'data/datasources/auction_remote_datasource.dart';
import 'data/repositories/auction_repository_impl.dart';
import 'data/repositories/auction_repository_mock_impl.dart';
import 'domain/repositories/auction_repository.dart';
import 'presentation/controllers/browse_controller.dart';

/// Dependency injection container for Browse module
class BrowseModule {
  static BrowseModule? _instance;
  static BrowseModule get instance => _instance ??= BrowseModule._();

  BrowseModule._();

  /// Toggle this to switch between mock and real data
  /// true = Use mock data (no Supabase needed)
  /// false = Use Supabase backend
  static const bool useMockData = true;

  /// Create auction remote data source
  AuctionRemoteDataSource _createRemoteDataSource() {
    return AuctionRemoteDataSource(SupabaseService.instance);
  }

  /// Create mock data source
  AuctionMockDataSource _createMockDataSource() {
    return AuctionMockDataSource();
  }

  /// Create auction repository (switches based on useMockData flag)
  AuctionRepository _createRepository() {
    if (useMockData) {
      // Use mock data - no backend needed
      return AuctionRepositoryMockImpl(_createMockDataSource());
    } else {
      // Use real Supabase backend
      return AuctionRepositoryImpl(_createRemoteDataSource());
    }
  }

  /// Create browse controller
  BrowseController createBrowseController() {
    return BrowseController(_createRepository());
  }
}
