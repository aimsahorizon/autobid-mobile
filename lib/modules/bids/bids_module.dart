import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'data/datasources/user_bids_mock_datasource.dart';
import 'data/datasources/user_bids_supabase_datasource.dart';
import 'data/datasources/buyer_transaction_supabase_datasource.dart';
import 'presentation/controllers/bids_controller.dart';

/// Bids module dependency injection
/// Manages creation and lifecycle of controllers and data sources
///
/// Pattern: Singleton module with factory methods
/// Usage: BidsModule.instance.createBidsController()
class BidsModule {
  // Singleton instance
  static final BidsModule _instance = BidsModule._internal();
  static BidsModule get instance => _instance;

  BidsModule._internal();

  /// Toggle for mock data vs real Supabase backend
  /// Syncs with BrowseModule.useMockData
  static bool useMockData = true;

  // Data source instances (shared across controllers)
  final _mockDataSource = UserBidsMockDataSource();
  UserBidsSupabaseDataSource? _userBidsSupabaseDataSource;
  BuyerTransactionSupabaseDataSource? _buyerTransactionSupabaseDataSource;

  /// Singleton controller instance
  static BidsController? _bidsController;

  /// Create Supabase datasource for user bids
  UserBidsSupabaseDataSource _createUserBidsSupabaseDataSource() {
    return UserBidsSupabaseDataSource(SupabaseConfig.client);
  }

  /// Create Supabase datasource for buyer transactions
  BuyerTransactionSupabaseDataSource _createBuyerTransactionSupabaseDataSource() {
    return BuyerTransactionSupabaseDataSource(SupabaseConfig.client);
  }

  /// Get data source based on useMockData flag
  IUserBidsDataSource _getDataSource() {
    if (useMockData) {
      return _mockDataSource;
    } else {
      _userBidsSupabaseDataSource ??= _createUserBidsSupabaseDataSource();
      return _userBidsSupabaseDataSource!;
    }
  }

  /// Get or create bids controller (based on useMockData flag)
  BidsController get controller {
    if (_bidsController == null) {
      _bidsController = BidsController(_getDataSource());
    }
    return _bidsController!;
  }

  /// Creates a new BidsController instance
  /// Called when BidsPage is mounted
  /// Switches between mock and Supabase data source based on useMockData flag
  BidsController createBidsController() {
    return BidsController(_getDataSource());
  }

  /// Toggle demo mode (switch between mock and Supabase)
  static void toggleDemoMode() {
    useMockData = !useMockData;
    dispose();
  }

  /// Dispose resources when module is no longer needed
  static void dispose() {
    _bidsController?.dispose();
    _bidsController = null;
  }

  /// Factory constructor for dependency injection frameworks
  /// Allows external DI containers to manage lifecycle
  factory BidsModule() => _instance;
}
