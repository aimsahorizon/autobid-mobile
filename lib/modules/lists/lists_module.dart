import 'package:get_it/get_it.dart';
import 'presentation/controllers/lists_controller.dart';
import 'presentation/controllers/listing_draft_controller.dart';
import 'data/datasources/listing_supabase_datasource.dart';
import '../transactions/presentation/controllers/transaction_controller.dart';

import 'domain/usecases/draft_management_usecases.dart';
import 'domain/usecases/submission_usecases.dart';
import 'domain/usecases/media_management_usecases.dart';
import 'data/repositories/seller_repository_impl.dart';
import 'domain/repositories/seller_repository.dart';
import 'domain/usecases/get_seller_listings_usecase.dart';
import 'domain/usecases/stream_seller_listings_usecase.dart';

/// Initialize Lists module dependencies
Future<void> initListsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton(() => ListingSupabaseDataSource(sl()));

  // Repositories
  sl.registerLazySingleton<SellerRepository>(
    () => SellerRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSellerListingsUseCase(sl()));
  sl.registerLazySingleton(() => GetSellerDraftsUseCase(sl()));
  sl.registerLazySingleton(() => GetDraftUseCase(sl()));
  sl.registerLazySingleton(() => CreateDraftUseCase(sl()));
  sl.registerLazySingleton(() => SaveDraftUseCase(sl()));
  sl.registerLazySingleton(() => MarkDraftCompleteUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDraftUseCase(sl()));
  sl.registerLazySingleton(() => SubmitListingUseCase(sl()));
  sl.registerLazySingleton(() => CancelListingUseCase(sl()));
  sl.registerLazySingleton(() => UploadListingPhotoUseCase(sl()));
  sl.registerLazySingleton(() => UploadDeedOfSaleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeedOfSaleUseCase(sl()));
  sl.registerLazySingleton(() => StreamSellerListingsUseCase(sl()));

  // Controllers (Factory)
  sl.registerFactory(() => ListsController(sl(), sl(), sl()));
  sl.registerFactory(() => ListingDraftController(
    getSellerDraftsUseCase: sl(),
    getDraftUseCase: sl(),
    createDraftUseCase: sl(),
    saveDraftUseCase: sl(),
    markDraftCompleteUseCase: sl(),
    deleteDraftUseCase: sl(),
    submitListingUseCase: sl(),
    uploadListingPhotoUseCase: sl(),
    uploadDeedOfSaleUseCase: sl(),
    deleteDeedOfSaleUseCase: sl(),
  ));
}

/// Lists module dependency injection (Legacy)
class ListsModule {
  /// Toggle for mock data vs real Supabase backend
  static bool useMockData = true;

  /// Singleton controller instances
  static ListsController? _listsController;
  static TransactionController? _transactionController;
  static ListingDraftController? _listingDraftController;

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
