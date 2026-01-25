import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'data/datasources/pricing_supabase_datasource.dart';
import 'data/datasources/profile_mock_datasource.dart';
import 'data/datasources/profile_supabase_datasource.dart';
import 'data/datasources/support_supabase_datasource.dart';
import 'data/repositories/pricing_repository_impl.dart';
import 'data/repositories/profile_repository_mock_impl.dart';
import 'data/repositories/profile_repository_supabase_impl.dart';
import 'data/repositories/support_repository_supabase_impl.dart';
import 'domain/repositories/pricing_repository.dart';
import 'domain/repositories/profile_repository.dart';
import 'domain/repositories/support_repository.dart';
import 'domain/usecases/get_support_categories_usecase.dart';
import 'domain/usecases/get_token_balance_usecase.dart';
import 'domain/usecases/get_token_packages_usecase.dart';
import 'domain/usecases/get_user_subscription_usecase.dart';
import 'domain/usecases/get_user_tickets_usecase.dart';
import 'domain/usecases/get_ticket_by_id_usecase.dart';
import 'domain/usecases/create_support_ticket_usecase.dart';
import 'domain/usecases/add_ticket_message_usecase.dart';
import 'domain/usecases/purchase_token_package_usecase.dart';
import 'domain/usecases/subscribe_to_plan_usecase.dart';
import 'domain/usecases/update_ticket_status_usecase.dart';
import 'domain/usecases/check_email_exists_usecase.dart';
import 'domain/usecases/get_user_profile_by_email_usecase.dart';
import 'domain/usecases/consume_bidding_token_usecase.dart';
import 'domain/usecases/upload_profile_photo_usecase.dart';
import 'domain/usecases/upload_cover_photo_usecase.dart';
import 'domain/usecases/update_profile_with_photo_usecase.dart';
import 'presentation/controllers/pricing_controller.dart';
import 'presentation/controllers/profile_controller.dart';
import 'presentation/controllers/support_controller.dart';

/// Initialize Profile module dependencies
Future<void> initProfileModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton<ProfileSupabaseDataSource>(
    () => ProfileSupabaseDataSource(sl()),
  );
  sl.registerLazySingleton<SupportSupabaseDatasource>(
    () => SupportSupabaseDatasource(sl()),
  );
  sl.registerLazySingleton<PricingSupabaseDatasource>(
    () => PricingSupabaseDatasource(supabase: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositorySupabaseImpl(sl()),
  );
  sl.registerLazySingleton<SupportRepository>(
    () => SupportRepositorySupabaseImpl(sl()),
  );
  sl.registerLazySingleton<PricingRepository>(
    () => PricingRepositoryImpl(datasource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CheckEmailExistsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileByEmailUseCase(sl()));
  sl.registerLazySingleton(() => UploadProfilePhotoUseCase(sl()));
  sl.registerLazySingleton(() => UploadCoverPhotoUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileWithPhotoUseCase(sl()));
  sl.registerLazySingleton(() => GetTokenBalanceUsecase(repository: sl()));
  sl.registerLazySingleton(() => GetUserSubscriptionUsecase(repository: sl()));
  sl.registerLazySingleton(() => GetTokenPackagesUsecase(repository: sl()));
  sl.registerLazySingleton(() => PurchaseTokenPackageUsecase(repository: sl()));
  sl.registerLazySingleton(() => SubscribeToPlanUsecase(repository: sl()));
  sl.registerLazySingleton(() => ConsumeBiddingTokenUsecase(repository: sl()));

  // Support Use Cases
  sl.registerLazySingleton(() => GetSupportCategoriesUsecase(sl()));
  sl.registerLazySingleton(() => GetUserTicketsUsecase(sl()));
  sl.registerLazySingleton(() => GetTicketByIdUsecase(sl()));
  sl.registerLazySingleton(() => CreateSupportTicketUsecase(sl()));
  sl.registerLazySingleton(() => AddTicketMessageUsecase(sl()));
  sl.registerLazySingleton(() => UpdateTicketStatusUsecase(sl()));

  // Controllers (Factory)
  sl.registerFactory(
    () => ProfileController(
      repository: sl(),
      uploadProfilePhotoUseCase: sl(),
      uploadCoverPhotoUseCase: sl(),
      updateProfileWithPhotoUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => PricingController(
      getTokenBalanceUsecase: sl(),
      getUserSubscriptionUsecase: sl(),
      getTokenPackagesUsecase: sl(),
      purchaseTokenPackageUsecase: sl(),
      subscribeToPlanUsecase: sl(),
    ),
  );
  sl.registerFactory(
    () => SupportController(
      getSupportCategoriesUsecase: sl(),
      getUserTicketsUsecase: sl(),
      getTicketByIdUsecase: sl(),
      createSupportTicketUsecase: sl(),
      addTicketMessageUsecase: sl(),
      updateTicketStatusUsecase: sl(),
    ),
  );
}

/// Dependency injection container for Profile module
class ProfileModule {
  static ProfileModule? _instance;
  static ProfileModule get instance => _instance ??= ProfileModule._();

  ProfileModule._();

  /// Toggle this to switch between mock and real data
  static const bool useMockData = false;

  /// Singleton instances
  ProfileSupabaseDataSource? _dataSourceInstance;
  ProfileRepository? _repositoryInstance;
  ProfileController? _controllerInstance;

  /// Create mock data source
  ProfileMockDataSource _createMockDataSource() {
    return ProfileMockDataSource();
  }

  /// Create Supabase data source
  ProfileSupabaseDataSource _getOrCreateDataSource() {
    _dataSourceInstance ??= ProfileSupabaseDataSource(SupabaseConfig.client);
    return _dataSourceInstance!;
  }

  /// Create profile repository
  ProfileRepository _getOrCreateRepository() {
    if (_repositoryInstance != null) return _repositoryInstance!;

    if (useMockData) {
      _repositoryInstance = ProfileRepositoryMockImpl(_createMockDataSource());
    } else {
      _repositoryInstance = ProfileRepositorySupabaseImpl(
        _getOrCreateDataSource(),
      );
    }
    return _repositoryInstance!;
  }

  /// Expose repository for other modules (e.g. Auth)
  ProfileRepository get repository => _getOrCreateRepository();

  /// Get or create profile controller (singleton)
  /// @deprecated Use GetIt.instance.get<ProfileController>() instead
  @Deprecated('Use GetIt.instance.get<ProfileController>()')
  ProfileController get controller {
    // Return GetIt controller if available
    if (GetIt.instance.isRegistered<ProfileController>()) {
      return GetIt.instance<ProfileController>();
    }
    // Fallback to legacy implementation
    _controllerInstance ??= ProfileController(
      repository: _getOrCreateRepository(),
      uploadProfilePhotoUseCase: UploadProfilePhotoUseCase(
        _getOrCreateRepository(),
      ),
      uploadCoverPhotoUseCase: UploadCoverPhotoUseCase(
        _getOrCreateRepository(),
      ),
      updateProfileWithPhotoUseCase: UpdateProfileWithPhotoUseCase(
        _getOrCreateRepository(),
      ),
    );
    return _controllerInstance!;
  }

  /// Create profile controller (deprecated - use controller getter instead)
  @Deprecated('Use ProfileModule.instance.controller instead')
  ProfileController createProfileController() {
    return controller;
  }

  /// Create support data source
  SupportSupabaseDatasource _createSupportDataSource() {
    return SupportSupabaseDatasource(SupabaseConfig.client);
  }

  /// Create support repository
  SupportRepository _createSupportRepository() {
    return SupportRepositorySupabaseImpl(_createSupportDataSource());
  }

  /// Create support use cases
  GetSupportCategoriesUsecase _createGetSupportCategoriesUsecase() {
    return GetSupportCategoriesUsecase(_createSupportRepository());
  }

  GetUserTicketsUsecase _createGetUserTicketsUsecase() {
    return GetUserTicketsUsecase(_createSupportRepository());
  }

  GetTicketByIdUsecase _createGetTicketByIdUsecase() {
    return GetTicketByIdUsecase(_createSupportRepository());
  }

  CreateSupportTicketUsecase _createCreateSupportTicketUsecase() {
    return CreateSupportTicketUsecase(_createSupportRepository());
  }

  AddTicketMessageUsecase _createAddTicketMessageUsecase() {
    return AddTicketMessageUsecase(_createSupportRepository());
  }

  UpdateTicketStatusUsecase _createUpdateTicketStatusUsecase() {
    return UpdateTicketStatusUsecase(_createSupportRepository());
  }

  /// Create support controller
  SupportController createSupportController() {
    return SupportController(
      getSupportCategoriesUsecase: _createGetSupportCategoriesUsecase(),
      getUserTicketsUsecase: _createGetUserTicketsUsecase(),
      getTicketByIdUsecase: _createGetTicketByIdUsecase(),
      createSupportTicketUsecase: _createCreateSupportTicketUsecase(),
      addTicketMessageUsecase: _createAddTicketMessageUsecase(),
      updateTicketStatusUsecase: _createUpdateTicketStatusUsecase(),
    );
  }

  /// Create pricing data source
  PricingSupabaseDatasource _createPricingDataSource() {
    return PricingSupabaseDatasource(supabase: SupabaseConfig.client);
  }

  /// Create pricing repository
  PricingRepositoryImpl _createPricingRepository() {
    return PricingRepositoryImpl(datasource: _createPricingDataSource());
  }

  /// Create pricing use cases
  GetTokenBalanceUsecase _createGetTokenBalanceUsecase() {
    return GetTokenBalanceUsecase(repository: _createPricingRepository());
  }

  GetUserSubscriptionUsecase _createGetUserSubscriptionUsecase() {
    return GetUserSubscriptionUsecase(repository: _createPricingRepository());
  }

  GetTokenPackagesUsecase _createGetTokenPackagesUsecase() {
    return GetTokenPackagesUsecase(repository: _createPricingRepository());
  }

  PurchaseTokenPackageUsecase _createPurchaseTokenPackageUsecase() {
    return PurchaseTokenPackageUsecase(repository: _createPricingRepository());
  }

  SubscribeToPlanUsecase _createSubscribeToPlanUsecase() {
    return SubscribeToPlanUsecase(repository: _createPricingRepository());
  }

  /// Create pricing controller
  PricingController createPricingController() {
    return PricingController(
      getTokenBalanceUsecase: _createGetTokenBalanceUsecase(),
      getUserSubscriptionUsecase: _createGetUserSubscriptionUsecase(),
      getTokenPackagesUsecase: _createGetTokenPackagesUsecase(),
      purchaseTokenPackageUsecase: _createPurchaseTokenPackageUsecase(),
      subscribeToPlanUsecase: _createSubscribeToPlanUsecase(),
    );
  }
}
