import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/transaction_mock_datasource.dart';
import 'data/datasources/transaction_supabase_datasource.dart';
import 'data/datasources/transaction_realtime_datasource.dart';
import 'data/datasources/seller_transaction_supabase_datasource.dart';
import 'data/datasources/chat_supabase_datasource.dart';
import 'data/datasources/timeline_supabase_datasource.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/controllers/transaction_realtime_controller.dart';
import 'presentation/controllers/transactions_status_controller.dart';
import 'presentation/controllers/seller_transaction_demo_controller.dart';
import 'presentation/controllers/buyer_seller_transactions_controller.dart';

/// Initialize Transactions module dependencies
Future<void> initTransactionsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton(() => TransactionMockDataSource());
  sl.registerLazySingleton(() => TransactionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => SellerTransactionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => ChatSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => TimelineSupabaseDataSource(sl()));

  // Controllers (Factory)
  sl.registerFactory(() => TransactionController(sl<TransactionMockDataSource>()));
  sl.registerFactory(() => TransactionRealtimeController(
    TransactionRealtimeDataSource(sl()),
  ));
  sl.registerFactory(() => TransactionsStatusController(
    sl(), // TransactionSupabaseDataSource
    sl<SupabaseClient>().auth.currentUser?.id ?? '',
  ));
  sl.registerFactory(() => BuyerSellerTransactionsController(
    sl<TransactionSupabaseDataSource>(),
    null,
    sl<SupabaseClient>().auth.currentUser?.id ?? '',
  ));
}

/// Transactions Module - Manages buyer-seller transactions (Legacy)
class TransactionsModule {
  static final TransactionsModule _instance = TransactionsModule._internal();
  static TransactionsModule get instance => _instance;

  TransactionsModule._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Datasources
  late final TransactionMockDataSource _mockDataSource;
  late final TransactionSupabaseDataSource _transactionSupabaseDataSource;
  late final SellerTransactionSupabaseDataSource _sellerTransactionDataSource;
  late final ChatSupabaseDataSource _chatDataSource;
  late final TimelineSupabaseDataSource _timelineDataSource;

  /// Initialize module and datasources
  void initialize() {
    _mockDataSource = TransactionMockDataSource();
    _transactionSupabaseDataSource = TransactionSupabaseDataSource(_supabase);
    _sellerTransactionDataSource = SellerTransactionSupabaseDataSource(
      _supabase,
    );
    _chatDataSource = ChatSupabaseDataSource(_supabase);
    _timelineDataSource = TimelineSupabaseDataSource(_supabase);
  }

  /// Create transaction controller (legacy - uses mock data)
  ///
  /// [useMockData] - If true, uses mock datasource. If false, uses Supabase
  TransactionController createTransactionController({bool useMockData = true}) {
    // For now, always use mock datasource since it has the fallback logic
    // to create dynamic transactions for any listing ID
    return TransactionController(_mockDataSource);
  }

  /// Create real-time transaction controller (recommended)
  /// Uses Supabase with real-time subscriptions for chat
  TransactionRealtimeController createRealtimeTransactionController() {
    return TransactionRealtimeController(
      TransactionRealtimeDataSource(_supabase),
    );
  }

  /// Create seller transaction demo controller
  SellerTransactionDemoController createDemoController(
    TransactionController transactionController,
    String sellerId,
    String sellerName,
  ) {
    return SellerTransactionDemoController(
      transactionController,
      sellerId,
      sellerName,
    );
  }

  /// Create transactions status controller for status-based transactions
  /// (in_transaction, sold, deal_failed)
  TransactionsStatusController createTransactionsStatusController() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to view transactions');
    }
    return TransactionsStatusController(_transactionSupabaseDataSource, userId);
  }

  /// Clean up resources
  void dispose() {
    // Clean up any resources if needed
  }
}
