import '../../app/core/config/supabase_config.dart';
import '../profile/data/datasources/pricing_supabase_datasource.dart';
import '../profile/data/repositories/pricing_repository_impl.dart';
import '../profile/domain/usecases/consume_bidding_token_usecase.dart';
import 'data/datasources/auction_detail_mock_datasource.dart';
import 'data/datasources/auction_mock_datasource.dart';
import 'data/datasources/auction_supabase_datasource.dart';
import 'data/datasources/bid_supabase_datasource.dart';
import 'data/datasources/qa_supabase_datasource.dart';
import 'data/repositories/auction_repository_mock_impl.dart';
import 'data/repositories/auction_repository_supabase_impl.dart';
import 'domain/repositories/auction_repository.dart';
import 'presentation/controllers/auction_detail_controller.dart';
import 'presentation/controllers/browse_controller.dart';

/// Dependency injection container for Browse module
class BrowseModule {
  static BrowseModule? _instance;
  static BrowseModule get instance => _instance ??= BrowseModule._();

  BrowseModule._();

  /// Toggle this to switch between mock and real data
  /// true = Use mock data (no Supabase needed)
  /// false = Use Supabase backend
  static bool useMockData = false;

  /// Singleton controller instances
  static BrowseController? _browseController;

  /// Create Supabase datasources
  AuctionSupabaseDataSource _createAuctionSupabaseDataSource() {
    return AuctionSupabaseDataSource(SupabaseConfig.client);
  }

  BidSupabaseDataSource _createBidSupabaseDataSource() {
    return BidSupabaseDataSource(SupabaseConfig.client);
  }

  QASupabaseDataSource _createQASupabaseDataSource() {
    return QASupabaseDataSource(SupabaseConfig.client);
  }

  /// Create pricing datasource for token consumption
  PricingSupabaseDatasource _createPricingSupabaseDataSource() {
    return PricingSupabaseDatasource(supabase: SupabaseConfig.client);
  }

  /// Create consume bidding token use case
  ConsumeBiddingTokenUsecase _createConsumeBiddingTokenUsecase() {
    final datasource = _createPricingSupabaseDataSource();
    final repository = PricingRepositoryImpl(datasource: datasource);
    return ConsumeBiddingTokenUsecase(repository: repository);
  }

  /// Create mock data source
  AuctionMockDataSource _createMockDataSource() {
    return AuctionMockDataSource();
  }

  /// Create auction detail mock data source
  AuctionDetailMockDataSource _createDetailMockDataSource() {
    return AuctionDetailMockDataSource();
  }

  /// Create auction repository (switches based on useMockData flag)
  AuctionRepository _createRepository() {
    if (useMockData) {
      return AuctionRepositoryMockImpl(_createMockDataSource());
    } else {
      return AuctionRepositorySupabaseImpl(_createAuctionSupabaseDataSource());
    }
  }

  /// Get or create browse controller (based on useMockData flag)
  BrowseController get controller {
    if (_browseController == null) {
      _browseController = BrowseController(_createRepository());
    }
    return _browseController!;
  }

  /// Create browse controller
  BrowseController createBrowseController() {
    return BrowseController(_createRepository());
  }

  /// Toggle demo mode (switch between mock and Supabase)
  static void toggleDemoMode() {
    useMockData = !useMockData;
    dispose();
  }

  /// Dispose resources when module is no longer needed
  static void dispose() {
    _browseController?.dispose();
    _browseController = null;
  }

  /// Create auction detail controller (switches based on useMockData flag)
  AuctionDetailController createAuctionDetailController() {
    if (useMockData) {
      return AuctionDetailController.mock(_createDetailMockDataSource());
    } else {
      return AuctionDetailController.supabase(
        auctionDataSource: _createAuctionSupabaseDataSource(),
        bidDataSource: _createBidSupabaseDataSource(),
        qaDataSource: _createQASupabaseDataSource(),
        consumeBiddingTokenUsecase: _createConsumeBiddingTokenUsecase(),
        userId: SupabaseConfig.client.auth.currentUser?.id,
      );
    }
  }
}
