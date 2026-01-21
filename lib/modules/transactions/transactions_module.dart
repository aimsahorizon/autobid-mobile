import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/transaction_remote_datasource.dart';
import 'data/datasources/transaction_composite_supabase_datasource.dart';
import 'data/datasources/transaction_mock_datasource.dart';
import 'data/datasources/transaction_supabase_datasource.dart';
import 'data/datasources/transaction_realtime_datasource.dart';
import 'data/datasources/seller_transaction_supabase_datasource.dart';
import 'data/datasources/buyer_transaction_supabase_datasource.dart';
import 'data/datasources/chat_supabase_datasource.dart';
import 'data/datasources/timeline_supabase_datasource.dart';
import 'data/repositories/transaction_repository_impl.dart';
import 'domain/repositories/transaction_repository.dart';
import 'domain/usecases/get_transaction_usecases.dart';
import 'domain/usecases/manage_transaction_usecases.dart';
import 'presentation/controllers/transaction_controller.dart';
import 'presentation/controllers/transaction_realtime_controller.dart';
import 'presentation/controllers/transactions_status_controller.dart';
import 'presentation/controllers/seller_transaction_demo_controller.dart';
import 'presentation/controllers/buyer_seller_transactions_controller.dart';

/// Initialize Transactions module dependencies
Future<void> initTransactionsModule() async {
  final sl = GetIt.instance;

  // Primitive Datasources
  sl.registerLazySingleton(() => TransactionMockDataSource());
  sl.registerLazySingleton(() => TransactionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => SellerTransactionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => BuyerTransactionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => ChatSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => TimelineSupabaseDataSource(sl()));

  // Composite Datasource (Remote Interface)
  sl.registerLazySingleton<TransactionRemoteDataSource>(
    () => TransactionCompositeSupabaseDataSource(
      transactionDataSource: sl(),
      chatDataSource: sl(),
      sellerDataSource: sl(),
      buyerDataSource: sl(),
      timelineDataSource: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetTransactionUseCase(sl()));
  sl.registerLazySingleton(() => GetChatMessagesUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionFormUseCase(sl()));
  sl.registerLazySingleton(() => GetTimelineUseCase(sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => SubmitFormUseCase(sl()));
  sl.registerLazySingleton(() => ConfirmFormUseCase(sl()));
  sl.registerLazySingleton(() => SubmitToAdminUseCase(sl()));
  sl.registerLazySingleton(() => UpdateDeliveryStatusUseCase(sl()));
  sl.registerLazySingleton(() => AcceptVehicleUseCase(sl()));
  sl.registerLazySingleton(() => RejectVehicleUseCase(sl()));

  // Controllers (Factory)
  sl.registerFactory(() => TransactionController(
    getTransactionUseCase: sl(),
    getChatMessagesUseCase: sl(),
    getTransactionFormUseCase: sl(),
    getTimelineUseCase: sl(),
    sendMessageUseCase: sl(),
    submitFormUseCase: sl(),
    confirmFormUseCase: sl(),
    submitToAdminUseCase: sl(),
    updateDeliveryStatusUseCase: sl(),
    acceptVehicleUseCase: sl(),
    rejectVehicleUseCase: sl(),
  ));

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
  
  // Legacy methods removed as they are replaced by DI
  // Keeping class for potential static references if any remain
  
  TransactionRealtimeController createRealtimeTransactionController() {
    // Fallback for any legacy calls not yet using sl
    return TransactionRealtimeController(
      TransactionRealtimeDataSource(Supabase.instance.client),
    );
  }
}