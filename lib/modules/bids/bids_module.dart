import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'data/datasources/bids_remote_datasource.dart';
import 'data/datasources/user_bids_supabase_datasource.dart';
import 'data/repositories/bids_repository_impl.dart';
import 'domain/repositories/bids_repository.dart';
import 'domain/usecases/get_user_bids_usecase.dart';
import 'presentation/controllers/bids_controller.dart';
import '../auth/auth_module.dart'; // Ensure AuthModule is available for AuthRepository

/// Initialize Bids module dependencies
Future<void> initBidsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton<BidsRemoteDataSource>(
    () => UserBidsSupabaseDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<BidsRepository>(
    () => BidsRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetUserBidsUseCase(sl()));

  // Controllers (Factory)
  // BidsController needs AuthRepository which is registered in AuthModule
  sl.registerFactory(() => BidsController(
    sl(), // GetUserBidsUseCase
    sl(), // AuthRepository
  ));
}

/// Legacy BidsModule class (Deprecated)
/// Kept for potential backward compatibility references during migration
class BidsModule {
  static final BidsModule _instance = BidsModule._internal();
  static BidsModule get instance => _instance;
  BidsModule._internal();
}