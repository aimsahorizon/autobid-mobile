import '../../app/core/config/supabase_config.dart';
import '../profile/data/datasources/pricing_supabase_datasource.dart';
import '../profile/data/repositories/pricing_repository_impl.dart';
import '../profile/domain/usecases/consume_listing_token_usecase.dart';
import 'presentation/controllers/lists_controller.dart';
import 'presentation/controllers/listing_draft_controller.dart';
import 'data/datasources/listing_draft_mock_datasource.dart';
import 'data/datasources/listing_supabase_datasource.dart';
import '../transactions/presentation/controllers/transaction_controller.dart';
import '../transactions/data/datasources/transaction_mock_datasource.dart';
import '../transactions/data/datasources/seller_transaction_supabase_datasource.dart';
import '../transactions/data/datasources/chat_supabase_datasource.dart';
import '../transactions/data/datasources/timeline_supabase_datasource.dart';

/// Lists module dependency injection
/// Handles seller listing management, transactions, and draft creation
class ListsModule {
  /// Toggle for mock data vs real Supabase backend
  static bool useMockData = true;

  /// Singleton controller instances
  static ListsController? _listsController;
  static TransactionController? _transactionController;
  static ListingDraftController? _listingDraftController;

  /// Data sources
  static TransactionMockDataSource? _transactionDataSource;
  static ListingDraftMockDataSource? _listingDraftDataSource;
  static ListingSupabaseDataSource? _listingSupabaseDataSource;
  static SellerTransactionSupabaseDataSource?
  _sellerTransactionSupabaseDataSource;
  static ChatSupabaseDataSource? _chatSupabaseDataSource;
  static TimelineSupabaseDataSource? _timelineSupabaseDataSource;

  /// Create Supabase datasources
  static ListingSupabaseDataSource _createListingSupabaseDataSource() {
    return ListingSupabaseDataSource(SupabaseConfig.client);
  }

  static SellerTransactionSupabaseDataSource
  _createSellerTransactionSupabaseDataSource() {
    return SellerTransactionSupabaseDataSource(SupabaseConfig.client);
  }

  static ChatSupabaseDataSource _createChatSupabaseDataSource() {
    return ChatSupabaseDataSource(SupabaseConfig.client);
  }

  static TimelineSupabaseDataSource _createTimelineSupabaseDataSource() {
    return TimelineSupabaseDataSource(SupabaseConfig.client);
  }

  /// Create pricing datasource for token consumption
  static PricingSupabaseDatasource _createPricingSupabaseDataSource() {
    return PricingSupabaseDatasource(supabase: SupabaseConfig.client);
  }

  /// Create consume listing token use case
  static ConsumeListingTokenUsecase _createConsumeListingTokenUsecase() {
    final datasource = _createPricingSupabaseDataSource();
    final repository = PricingRepositoryImpl(datasource: datasource);
    return ConsumeListingTokenUsecase(repository: repository);
  }

  /// Get or create the lists controller (based on useMockData flag)
  static ListsController get controller {
    if (_listsController == null) {
      _listsController = useMockData
          ? ListsController.mock()
          : ListsController.supabase();
    }
    return _listsController!;
  }

  /// Create transaction controller for specific transaction
  static TransactionController createTransactionController() {
    if (useMockData) {
      _transactionDataSource ??= TransactionMockDataSource();
      return TransactionController(_transactionDataSource!);
    } else {
      _transactionDataSource ??=
          TransactionMockDataSource(); // Fallback to mock for now
      _sellerTransactionSupabaseDataSource ??=
          _createSellerTransactionSupabaseDataSource();
      _chatSupabaseDataSource ??= _createChatSupabaseDataSource();
      _timelineSupabaseDataSource ??= _createTimelineSupabaseDataSource();
      // TODO: Update TransactionController to accept Supabase datasources
      return TransactionController(_transactionDataSource!);
    }
  }

  /// Create listing draft controller for creating/editing listings
  static ListingDraftController createListingDraftController() {
    if (useMockData) {
      _listingDraftDataSource ??= ListingDraftMockDataSource();
      return ListingDraftController.mock(_listingDraftDataSource!);
    } else {
      _listingSupabaseDataSource ??= _createListingSupabaseDataSource();
      return ListingDraftController.supabase(
        _listingSupabaseDataSource!,
        consumeListingTokenUsecase: _createConsumeListingTokenUsecase(),
      );
    }
  }

  /// Toggle demo mode (switch between mock and Supabase)
  static void toggleDemoMode() {
    useMockData = !useMockData;
    // Dispose existing controllers to force recreation with new datasources
    dispose();
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
