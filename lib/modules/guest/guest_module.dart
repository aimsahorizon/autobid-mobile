import '../../app/core/config/supabase_config.dart';
import 'data/datasources/guest_supabase_datasource.dart';
import 'presentation/controllers/guest_controller.dart';

class GuestModule {
  static GuestModule? _instance;

  late final GuestSupabaseDataSource _dataSource;

  GuestModule._() {
    _initializeDependencies();
  }

  static GuestModule get instance {
    _instance ??= GuestModule._();
    return _instance!;
  }

  void _initializeDependencies() {
    _dataSource = GuestSupabaseDataSource(SupabaseConfig.client);
  }

  GuestController createGuestController() {
    return GuestController(dataSource: _dataSource);
  }
}
