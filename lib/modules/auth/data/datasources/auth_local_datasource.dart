import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheRememberMe(bool value);
  Future<bool> getRememberMe();
  Future<void> cacheUsername(String username);
  Future<String?> getCachedUsername();
  Future<void> clearCachedUsername();
}

const String CACHED_REMEMBER_ME = 'CACHED_REMEMBER_ME';
const String CACHED_USERNAME = 'CACHED_USERNAME';

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<void> cacheRememberMe(bool value) async {
    await sharedPreferences.setBool(CACHED_REMEMBER_ME, value);
  }

  @override
  Future<bool> getRememberMe() async {
    return sharedPreferences.getBool(CACHED_REMEMBER_ME) ?? false;
  }

  @override
  Future<void> cacheUsername(String username) async {
    await sharedPreferences.setString(CACHED_USERNAME, username);
  }

  @override
  Future<String?> getCachedUsername() async {
    return sharedPreferences.getString(CACHED_USERNAME);
  }

  @override
  Future<void> clearCachedUsername() async {
    await sharedPreferences.remove(CACHED_USERNAME);
  }
}
