import 'package:get_it/get_it.dart';
import 'data/datasources/guest_supabase_datasource.dart';
import 'data/datasources/guest_remote_datasource.dart';
import 'data/repositories/guest_repository_impl.dart';
import 'domain/repositories/guest_repository.dart';
import 'domain/usecases/check_account_status_usecase.dart';
import 'domain/usecases/get_guest_auction_listings_usecase.dart';
import 'presentation/controllers/guest_controller.dart';

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
    () => GuestRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CheckAccountStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetGuestAuctionListingsUseCase(sl()));

  // Controllers (Factory - create new instance each time)
  sl.registerFactory(
    () => GuestController(
      checkAccountStatusUseCase: sl(),
      getGuestAuctionListingsUseCase: sl(),
    ),
  );
}

/// Legacy Dependency injection container for Guest module
/// @deprecated - Use GetIt service locator via initGuestModule() instead
class GuestModule {
  static GuestModule? _instance;

  GuestModule._() {
    _initializeDependencies();
  }

  static GuestModule get instance {
    _instance ??= GuestModule._();
    return _instance!;
  }

  void _initializeDependencies() {
    // Dependencies are now managed via GetIt in initGuestModule()
  }

  /// @deprecated - Use GetIt.instance.get<GuestController>() instead
  GuestController createGuestController() {
    return GetIt.instance<GuestController>();
  }
}
