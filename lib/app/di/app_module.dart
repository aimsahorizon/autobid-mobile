import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

/// Initialize all application dependencies.
/// This method should be called in main.dart before runApp.
Future<void> initDependencies() async {
  // 1. External Dependencies (Supabase, SharedPreferences, etc.)
  // TODO: Move SupabaseConfig and StripeService init here if possible/appropriate
  
  // 2. Core Dependencies
  // sl.registerLazySingleton(() => ...);

  // 3. Feature Modules
  // Call initialization methods for each module
  // await AuthModule.init();
}
