import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/file_encryption_service.dart';
// Import module initializers
import '../../modules/auth/auth_module.dart';
import '../../modules/profile/profile_module.dart';
import '../../modules/bids/bids_module.dart';
import '../../modules/browse/browse_module.dart';
import '../../modules/notifications/notifications_module.dart';
import '../../modules/lists/lists_module.dart';
import '../../modules/admin/admin_module.dart';
import '../../modules/transactions/transactions_module.dart';

final sl = GetIt.instance;

/// Initialize all application dependencies.
/// This method should be called in main.dart before runApp.
Future<void> initDependencies() async {
  // 1. External Dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // SupabaseClient - Lazy registration
  // Note: SupabaseConfig.initialize() is called in main.dart
  sl.registerLazySingleton<SupabaseClient>((() => SupabaseConfig.client));

  // 2. Core Dependencies
  sl.registerLazySingleton(() => FileEncryptionService(sl()));

  // 3. Feature Modules
  await initProfileModule();
  await initAuthModule();
  await initBidsModule();
  await initBrowseModule();
  await initNotificationsModule();
  await initListsModule();
  await initAdminModule();
  await initTransactionsModule();
}