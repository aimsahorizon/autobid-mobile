import 'presentation/controllers/lists_controller.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/controllers/listing_draft_controller.dart';
import 'data/datasources/transaction_mock_datasource.dart';
import 'data/datasources/listing_draft_mock_datasource.dart';

/// Lists module dependency injection
/// Handles seller listing management, transactions, and draft creation
class ListsModule {
  /// Toggle for mock data vs real Supabase backend
  static const bool useMockData = true;

  /// Singleton controller instances
  static ListsController? _listsController;
  static TransactionController? _transactionController;
  static ListingDraftController? _listingDraftController;

  /// Data sources
  static TransactionMockDataSource? _transactionDataSource;
  static ListingDraftMockDataSource? _listingDraftDataSource;

  /// Get or create the lists controller
  static ListsController get controller {
    _listsController ??= ListsController();
    return _listsController!;
  }

  /// Create transaction controller for specific transaction
  static TransactionController createTransactionController() {
    _transactionDataSource ??= TransactionMockDataSource();
    return TransactionController(_transactionDataSource!);
  }

  /// Create listing draft controller for creating/editing listings
  static ListingDraftController createListingDraftController() {
    _listingDraftDataSource ??= ListingDraftMockDataSource();
    return ListingDraftController(_listingDraftDataSource!);
  }

  /// Dispose resources when module is no longer needed
  static void dispose() {
    _listsController?.dispose();
    _listsController = null;
    _transactionController?.dispose();
    _transactionController = null;
    _listingDraftController?.dispose();
    _listingDraftController = null;
  }
}
