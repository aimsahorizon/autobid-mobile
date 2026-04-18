import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/modules/guest/data/datasources/guest_supabase_datasource.dart';
import 'package:autobid_mobile/modules/guest/data/datasources/guest_remote_datasource.dart';
import 'package:autobid_mobile/modules/guest/data/repositories/guest_repository_impl.dart';
import 'package:autobid_mobile/modules/guest/domain/repositories/guest_repository.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/check_account_status_usecase.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/get_guest_auction_listings_usecase.dart';
import 'package:autobid_mobile/modules/guest/domain/usecases/submit_kyc_appeal_usecase.dart';
import 'package:autobid_mobile/modules/guest/presentation/controllers/guest_controller.dart';

/// Initialize Guest module dependencies
/// Following Clean Architecture with proper DI setup
Future<void> initGuestModule() async {
  final sl = GetIt.instance;

  // Data Sources
  sl.registerLazySingleton<GuestRemoteDataSource>(
    () => GuestSupabaseDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<GuestRepository>(
    () => GuestRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CheckAccountStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetGuestAuctionListingsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitKycAppealUseCase(sl()));

  // Controllers (Factory - create new instance each time)
  sl.registerFactory(
    () => GuestController(
      checkAccountStatusUseCase: sl(),
      getGuestAuctionListingsUseCase: sl(),
      submitKycAppealUseCase: sl(),
    ),
  );
}
