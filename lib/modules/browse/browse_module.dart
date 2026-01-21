import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../profile/domain/usecases/consume_bidding_token_usecase.dart';
import 'data/datasources/auction_supabase_datasource.dart';
import 'data/datasources/bid_supabase_datasource.dart';
import 'data/datasources/qa_supabase_datasource.dart';
import 'data/datasources/user_preferences_supabase_datasource.dart';
import 'data/datasources/deposit_supabase_datasource.dart';
import 'data/datasources/auction_detail_composite_supabase_datasource.dart';
import 'data/datasources/auction_detail_remote_datasource.dart';
import 'data/repositories/auction_repository_supabase_impl.dart';
import 'data/repositories/auction_detail_repository_impl.dart';
import 'domain/repositories/auction_repository.dart';
import 'domain/repositories/auction_detail_repository.dart';
import 'domain/usecases/get_auction_detail_usecase.dart';
import 'domain/usecases/get_bid_history_usecase.dart';
import 'domain/usecases/place_bid_usecase.dart';
import 'domain/usecases/get_questions_usecase.dart';
import 'domain/usecases/post_question_usecase.dart';
import 'domain/usecases/like_question_usecase.dart';
import 'domain/usecases/unlike_question_usecase.dart';
import 'domain/usecases/get_bid_increment_usecase.dart';
import 'domain/usecases/upsert_bid_increment_usecase.dart';
import 'domain/usecases/process_deposit_usecase.dart';
import 'presentation/controllers/auction_detail_controller.dart';
import 'presentation/controllers/browse_controller.dart';

/// Initialize Browse module dependencies
/// Following Clean Architecture with proper DI setup
Future<void> initBrowseModule() async {
  final sl = GetIt.instance;

  // Data Sources
  sl.registerLazySingleton(() => AuctionSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => BidSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => QASupabaseDataSource(sl()));
  sl.registerLazySingleton(
    () => UserPreferencesSupabaseDatasource(supabase: sl()),
  );
  sl.registerLazySingleton(() => DepositSupabaseDataSource(sl()));

  // Composite Data Source for Auction Detail
  sl.registerLazySingleton<AuctionDetailRemoteDataSource>(
    () => AuctionDetailCompositeSupabaseDataSource(
      auctionDataSource: sl(),
      bidDataSource: sl(),
      qaDataSource: sl(),
      userPreferencesDataSource: sl(),
      depositDataSource: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<AuctionRepository>(
    () => AuctionRepositorySupabaseImpl(sl()),
  );
  sl.registerLazySingleton<AuctionDetailRepository>(
    () => AuctionDetailRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases for Auction Detail
  sl.registerLazySingleton(() => GetAuctionDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetBidHistoryUseCase(sl()));
  sl.registerLazySingleton(() => PlaceBidUseCase(sl()));
  sl.registerLazySingleton(() => GetQuestionsUseCase(sl()));
  sl.registerLazySingleton(() => PostQuestionUseCase(sl()));
  sl.registerLazySingleton(() => LikeQuestionUseCase(sl()));
  sl.registerLazySingleton(() => UnlikeQuestionUseCase(sl()));
  sl.registerLazySingleton(() => GetBidIncrementUseCase(sl()));
  sl.registerLazySingleton(() => UpsertBidIncrementUseCase(sl()));
  sl.registerLazySingleton(() => ProcessDepositUseCase(sl()));

  // Controllers (Factory - create new instance each time)
  sl.registerFactory(() => BrowseController(sl()));
  sl.registerFactory(
    () => AuctionDetailController(
      getAuctionDetailUseCase: sl(),
      getBidHistoryUseCase: sl(),
      placeBidUseCase: sl(),
      getQuestionsUseCase: sl(),
      postQuestionUseCase: sl(),
      likeQuestionUseCase: sl(),
      unlikeQuestionUseCase: sl(),
      getBidIncrementUseCase: sl(),
      upsertBidIncrementUseCase: sl(),
      processDepositUseCase: sl(),
      consumeBiddingTokenUsecase: sl(),
      userId: sl<SupabaseClient>().auth.currentUser?.id,
    ),
  );
}

/// Legacy Dependency injection container for Browse module
/// @deprecated - Use GetIt service locator via initBrowseModule() instead
class BrowseModule {
  static BrowseModule? _instance;
  static BrowseModule get instance => _instance ??= BrowseModule._();

  BrowseModule._();

  /// @deprecated - Use GetIt service locator instead
  static bool useMockData = false;

  /// Singleton controller instances
  static BrowseController? _browseController;

  /// @deprecated - Use GetIt.instance.get<BrowseController>() instead
  BrowseController get controller {
    _browseController ??= GetIt.instance<BrowseController>();
    return _browseController!;
  }

  /// @deprecated - Use GetIt.instance.get<BrowseController>() instead
  BrowseController createBrowseController() {
    return GetIt.instance<BrowseController>();
  }

  /// @deprecated - No longer needed with GetIt
  static void toggleDemoMode() {
    useMockData = !useMockData;
    dispose();
  }

  /// Dispose resources when module is no longer needed
  static void dispose() {
    _browseController?.dispose();
    _browseController = null;
  }

  /// @deprecated - Use GetIt.instance.get<AuctionDetailController>() instead
  AuctionDetailController createAuctionDetailController() {
    return GetIt.instance<AuctionDetailController>();
  }
}
