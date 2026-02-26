import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheRememberMe(bool value);
  Future<bool> getRememberMe();
  Future<void> cacheUsername(String username);
  Future<String?> getCachedUsername();
  Future<void> clearCachedUsername();
  Future<void> cacheOnboardingCompleted();
  Future<bool> getOnboardingCompleted();
}

const String cachedRememberMe = 'CACHED_REMEMBER_ME';
const String cachedUsername = 'CACHED_USERNAME';
const String cachedOnboardingCompleted = 'CACHED_ONBOARDING_COMPLETED';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheRememberMe(bool value) async {
    await sharedPreferences.setBool(cachedRememberMe, value);
  }

  @override
  Future<bool> getRememberMe() async {
    return sharedPreferences.getBool(cachedRememberMe) ?? false;
  }

  @override
  Future<void> cacheUsername(String username) async {
    await sharedPreferences.setString(cachedUsername, username);
  }

  @override
  Future<String?> getCachedUsername() async {
    return sharedPreferences.getString(cachedUsername);
  }

  @override
  Future<void> clearCachedUsername() async {
    await sharedPreferences.remove(cachedUsername);
  }

  @override
  Future<void> cacheOnboardingCompleted() async {
    await sharedPreferences.setBool(cachedOnboardingCompleted, true);
  }

  @override
  Future<bool> getOnboardingCompleted() async {
    return sharedPreferences.getBool(cachedOnboardingCompleted) ?? false;
  }
}
