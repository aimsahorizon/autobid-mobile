import 'data/datasources/user_bids_mock_datasource.dart';
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

  // Data source instance (shared across controllers)
  final _dataSource = UserBidsMockDataSource();

  /// Creates a new BidsController instance
  /// Called when BidsPage is mounted
  /// In production, this will inject Supabase data source
  BidsController createBidsController() {
    return BidsController(_dataSource);
  }

  /// Factory constructor for dependency injection frameworks
  /// Allows external DI containers to manage lifecycle
  factory BidsModule() => _instance;
}
