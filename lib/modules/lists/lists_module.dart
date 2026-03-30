import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/services/car_api_service.dart';
import 'presentation/controllers/lists_controller.dart';
import 'presentation/controllers/listing_draft_controller.dart';
import 'data/datasources/listing_supabase_datasource.dart';
import 'data/datasources/vehicle_supabase_datasource.dart';

import 'domain/usecases/draft_management_usecases.dart';
import 'domain/usecases/submission_usecases.dart';
import 'domain/usecases/delete_listing_usecase.dart';
import 'domain/usecases/media_management_usecases.dart';
import 'data/repositories/seller_repository_impl.dart';
import 'data/repositories/vehicle_repository_impl.dart';
import 'domain/repositories/seller_repository.dart';
import 'domain/repositories/vehicle_repository.dart';
import 'domain/usecases/get_seller_listings_usecase.dart';
import 'domain/usecases/stream_seller_listings_usecase.dart';
import 'domain/usecases/validate_plate_number_usecase.dart';
import 'domain/usecases/get_vehicle_data_usecases.dart';
import 'domain/usecases/manage_invites_usecases.dart';

/// Initialize Lists module dependencies
Future<void> initListsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton(() => ListingSupabaseDataSource(sl()));
  sl.registerLazySingleton(() => VehicleSupabaseDataSource(sl()));
  // InvitesSupabaseDatasource is registered in browse_module.dart (its home module)

  // Services
  sl.registerLazySingleton(() => CarApiService(sl()));

  // Repositories
  sl.registerLazySingleton<SellerRepository>(
    () => SellerRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<VehicleRepository>(
    () => VehicleRepositoryImpl(sl(), sl()),
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
  sl.registerLazySingleton(() => DeleteListingUseCase(sl()));
  sl.registerLazySingleton(() => UploadListingPhotoUseCase(sl()));
  sl.registerLazySingleton(() => UploadDeedOfSaleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteDeedOfSaleUseCase(sl()));
  sl.registerLazySingleton(() => StreamSellerListingsUseCase(sl()));
  sl.registerLazySingleton(() => ValidatePlateNumberUseCase(sl()));

  // Invite Use Cases
  sl.registerLazySingleton(() => GetAuctionInvitesUseCase(sl()));
  sl.registerLazySingleton(() => InviteUserUseCase(sl()));
  sl.registerLazySingleton(() => DeleteInviteUseCase(sl()));

  // Vehicle Data Use Cases
  sl.registerLazySingleton(() => GetVehicleBrandsUseCase(sl()));
  sl.registerLazySingleton(() => GetVehicleModelsUseCase(sl()));
  sl.registerLazySingleton(() => GetVehicleVariantsUseCase(sl()));

  // Controllers (Factory)
  sl.registerFactory(
    () => ListsController(
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      getAuctionInvitesUseCase: sl(),
      inviteUserUseCase: sl(),
      deleteInviteUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => ListingDraftController(
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
      getVehicleBrandsUseCase: sl(),
      getVehicleModelsUseCase: sl(),
      getVehicleVariantsUseCase: sl(),
      getUserProfileUseCase: sl(),
      carApiService: sl(),
    ),
  );
}
