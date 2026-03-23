import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/auction_supabase_datasource.dart';
import 'data/datasources/bid_supabase_datasource.dart';
import 'data/datasources/qa_supabase_datasource.dart';
import 'data/datasources/user_preferences_supabase_datasource.dart';
import 'data/datasources/deposit_supabase_datasource.dart';
import 'data/datasources/auction_detail_composite_supabase_datasource.dart';
import 'data/datasources/auction_detail_remote_datasource.dart';
import 'data/datasources/invites_supabase_datasource.dart';
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
import 'domain/usecases/stream_auction_updates_usecase.dart';
import 'domain/usecases/stream_bid_updates_usecase.dart';
import 'domain/usecases/stream_qa_updates_usecase.dart';
import 'domain/usecases/stream_active_auctions_usecase.dart';
import 'domain/usecases/save_auto_bid_settings_usecase.dart';
import 'domain/usecases/get_auto_bid_settings_usecase.dart';
import 'domain/usecases/deactivate_auto_bid_usecase.dart';
import 'domain/usecases/buyer_invite_usecases.dart';
import 'domain/usecases/raise_hand_usecase.dart';
import 'domain/usecases/lower_hand_usecase.dart';
import 'domain/usecases/submit_turn_bid_usecase.dart';
import 'domain/usecases/get_queue_status_usecase.dart';
import 'domain/usecases/stream_queue_updates_usecase.dart';
import 'domain/usecases/place_mystery_bid_usecase.dart';
import 'domain/usecases/get_mystery_bid_status_usecase.dart';
import 'presentation/controllers/auction_detail_controller.dart';
import 'presentation/controllers/browse_controller.dart';
import 'presentation/controllers/buyer_invites_controller.dart';

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
  sl.registerLazySingleton(() => InvitesSupabaseDatasource(supabase: sl()));

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
    () => AuctionRepositorySupabaseImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuctionDetailRepository>(
    () =>
        AuctionDetailRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
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
  sl.registerLazySingleton(() => StreamAuctionUpdatesUseCase(sl()));
  sl.registerLazySingleton(() => StreamBidUpdatesUseCase(sl()));
  sl.registerLazySingleton(() => StreamQAUpdatesUseCase(sl()));
  sl.registerLazySingleton(() => StreamActiveAuctionsUseCase(sl()));
  sl.registerLazySingleton(
    () => SaveAutoBidSettingsUseCase(
      sl(),
      canUseAutoBid: (userId) async {
        final response = await sl<SupabaseClient>()
            .from('user_subscriptions')
            .select('plan')
            .eq('user_id', userId)
            .eq('is_active', true)
            .maybeSingle();

        if (response == null) return false;
        final plan = (response['plan'] as String? ?? '').toLowerCase();
        return plan == 'gold_monthly' ||
            plan == 'gold_yearly' ||
            plan == 'pro_plus_monthly' ||
            plan == 'pro_plus_yearly';
      },
    ),
  );
  sl.registerLazySingleton(() => GetAutoBidSettingsUseCase(sl()));
  sl.registerLazySingleton(() => DeactivateAutoBidUseCase(sl()));
  sl.registerLazySingleton(() => RaiseHandUseCase(sl()));
  sl.registerLazySingleton(() => LowerHandUseCase(sl()));
  sl.registerLazySingleton(() => SubmitTurnBidUseCase(sl()));
  sl.registerLazySingleton(() => GetQueueStatusUseCase(sl()));
  sl.registerLazySingleton(() => StreamQueueUpdatesUseCase(sl()));
  sl.registerLazySingleton(() => PlaceMysteryBidUseCase(sl()));
  sl.registerLazySingleton(() => GetMysteryBidStatusUseCase(sl()));

  // Buyer Invite Use Cases
  sl.registerLazySingleton(() => ListMyInvitesUseCase(sl()));
  sl.registerLazySingleton(() => RespondToInviteUseCase(sl()));

  // Controllers (Factory - create new instance each time)
  sl.registerFactory(() => BrowseController(sl(), sl()));
  sl.registerFactory(
    () => BuyerInvitesController(
      listMyInvitesUseCase: sl(),
      respondToInviteUseCase: sl(),
      datasource: sl(),
      userId: sl<SupabaseClient>().auth.currentUser?.id ?? '',
    ),
  );
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
      streamAuctionUpdatesUseCase: sl(),
      streamBidUpdatesUseCase: sl(),
      streamQAUpdatesUseCase: sl(),
      saveAutoBidSettingsUseCase: sl(),
      getAutoBidSettingsUseCase: sl(),
      deactivateAutoBidUseCase: sl(),
      raiseHandUseCase: sl(),
      lowerHandUseCase: sl(),
      submitTurnBidUseCase: sl(),
      getQueueStatusUseCase: sl(),
      streamQueueUpdatesUseCase: sl(),
      placeMysteryBidUseCase: sl(),
      getMysteryBidStatusUseCase: sl(),
      userId: sl<SupabaseClient>().auth.currentUser?.id,
    ),
  );
}
