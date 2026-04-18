import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/modules/bids/data/datasources/bids_remote_datasource.dart';
import 'package:autobid_mobile/modules/bids/data/datasources/user_bids_supabase_datasource.dart';
import 'package:autobid_mobile/modules/bids/data/repositories/bids_repository_impl.dart';
import 'package:autobid_mobile/modules/bids/domain/repositories/bids_repository.dart';
import 'package:autobid_mobile/modules/bids/domain/usecases/get_user_bids_usecase.dart';
import 'package:autobid_mobile/modules/bids/domain/usecases/stream_user_bids_usecase.dart';
import 'package:autobid_mobile/modules/bids/presentation/controllers/bids_controller.dart';
// Ensure AuthModule is available for AuthRepository

/// Initialize Bids module dependencies
Future<void> initBidsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton<BidsRemoteDataSource>(
    () => UserBidsSupabaseDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<BidsRepository>(
    () => BidsRepositoryImpl(sl(), sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetUserBidsUseCase(sl()));
  sl.registerLazySingleton(() => StreamUserBidsUseCase(sl()));

  // Controllers (Factory)
  // BidsController needs AuthRepository which is registered in AuthModule
  sl.registerFactory(() => BidsController(
    sl(), // GetUserBidsUseCase
    sl(), // StreamUserBidsUseCase
    sl(), // AuthRepository
  ));
}