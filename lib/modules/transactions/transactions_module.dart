import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/transaction_mock_datasource.dart';
import 'data/datasources/transaction_supabase_datasource.dart';
import 'data/datasources/seller_transaction_supabase_datasource.dart';
import 'data/datasources/chat_supabase_datasource.dart';
import 'data/datasources/timeline_supabase_datasource.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/controllers/transactions_status_controller.dart';
import 'presentation/controllers/seller_transaction_demo_controller.dart';

/// Transactions Module - Manages buyer-seller transactions
///
/// Handles the complete transaction lifecycle from initial discussion
/// through form submissions, admin approval, and delivery tracking.
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

  /// Create transaction controller
  ///
  /// [useMockData] - If true, uses mock datasource. If false, uses Supabase
  TransactionController createTransactionController({bool useMockData = true}) {
    // For now, always use mock datasource since it has the fallback logic
    // to create dynamic transactions for any listing ID
    return TransactionController(_mockDataSource);
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
