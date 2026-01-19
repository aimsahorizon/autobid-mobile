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

  // Repositories
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositorySupabaseImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => CheckEmailExistsUseCase(sl()));
  sl.registerLazySingleton(() => GetUserProfileByEmailUseCase(sl()));
  
  // Note: Other Profile usecases and controllers can be added here
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
      _repositoryInstance = ProfileRepositorySupabaseImpl(_getOrCreateDataSource());
    }
    return _repositoryInstance!;
  }
  
  /// Expose repository for other modules (e.g. Auth)
  ProfileRepository get repository => _getOrCreateRepository();

  /// Get or create profile controller (singleton)
  ProfileController get controller {
    _controllerInstance ??= ProfileController(_getOrCreateRepository(), _getOrCreateDataSource());
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
