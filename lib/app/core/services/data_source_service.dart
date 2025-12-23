import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage data source toggle between mock and Supabase
/// Stores preference locally using SharedPreferences
class DataSourceService extends ChangeNotifier {
  static const String _keyUseMockData = 'use_mock_data';

  // Default to mock data for development
  bool _useMockData = true;

  bool get useMockData => _useMockData;

  /// Initialize service and load saved preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _useMockData = prefs.getBool(_keyUseMockData) ?? true;
    notifyListeners();
  }

  /// Toggle between mock and Supabase data source
  Future<void> toggleDataSource() async {
    _useMockData = !_useMockData;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockData, _useMockData);

    notifyListeners();
  }

  /// Set data source explicitly
  Future<void> setDataSource(bool useMock) async {
    if (_useMockData == useMock) return;

    _useMockData = useMock;

    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockData, _useMockData);

    notifyListeners();
  }
}
