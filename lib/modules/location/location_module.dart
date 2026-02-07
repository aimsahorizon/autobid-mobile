import 'package:get_it/get_it.dart';
import 'data/datasources/location_remote_datasource.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/usecases/location_usecases.dart';
import 'presentation/bloc/location_bloc.dart';

final sl = GetIt.instance;

Future<void> initLocationModule() async {
  // Bloc
  sl.registerFactory(
    () => LocationBloc(
      getRegions: sl(),
      getProvinces: sl(),
      getCities: sl(),
      getBarangays: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetRegionsUseCase(sl()));
  sl.registerLazySingleton(() => GetProvincesUseCase(sl()));
  sl.registerLazySingleton(() => GetCitiesUseCase(sl()));
  sl.registerLazySingleton(() => GetBarangaysUseCase(sl()));

  // Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );

  // Data Source
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => LocationRemoteDataSourceImpl(sl()),
  );
}
