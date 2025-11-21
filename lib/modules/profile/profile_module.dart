import 'data/datasources/profile_mock_datasource.dart';
import 'data/repositories/profile_repository_mock_impl.dart';
import 'domain/repositories/profile_repository.dart';
import 'presentation/controllers/profile_controller.dart';

/// Dependency injection container for Profile module
class ProfileModule {
  static ProfileModule? _instance;
  static ProfileModule get instance => _instance ??= ProfileModule._();

  ProfileModule._();

  /// Toggle this to switch between mock and real data
  static const bool useMockData = true;

  /// Create mock data source
  ProfileMockDataSource _createMockDataSource() {
    return ProfileMockDataSource();
  }

  /// Create profile repository
  ProfileRepository _createRepository() {
    if (useMockData) {
      return ProfileRepositoryMockImpl(_createMockDataSource());
    } else {
      // TODO: Implement real Supabase repository
      return ProfileRepositoryMockImpl(_createMockDataSource());
    }
  }

  /// Create profile controller
  ProfileController createProfileController() {
    return ProfileController(_createRepository());
  }
}
