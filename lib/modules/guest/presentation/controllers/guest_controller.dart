import 'package:flutter/material.dart';
import '../../data/datasources/guest_supabase_datasource.dart';
import '../../data/datasources/guest_mock_datasource.dart';
import '../../domain/entities/account_status_entity.dart';

class GuestController extends ChangeNotifier {
  final GuestSupabaseDataSource dataSource;
  final GuestMockDataSource mockDataSource = GuestMockDataSource();

  GuestController({required this.dataSource});

  int _currentTabIndex = 0;
  bool _isLoadingStatus = false;
  bool _isLoadingAuctions = false;
  AccountStatusEntity? _accountStatus;
  List<Map<String, dynamic>> _auctions = [];
  String? _errorMessage;
  String? _statusEmail;
  bool _useMockData = false; // Toggle between mock and real data

  int get currentTabIndex => _currentTabIndex;
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isLoadingAuctions => _isLoadingAuctions;
  AccountStatusEntity? get accountStatus => _accountStatus;
  List<Map<String, dynamic>> get auctions => _auctions;
  String? get errorMessage => _errorMessage;
  String? get statusEmail => _statusEmail;
  bool get useMockData => _useMockData;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  Future<void> checkAccountStatus(String email) async {
    _isLoadingStatus = true;
    _errorMessage = null;
    _statusEmail = email;
    notifyListeners();

    try {
      _accountStatus = await dataSource.checkAccountStatus(email);
      _isLoadingStatus = false;
      notifyListeners();
    } catch (e) {
      _isLoadingStatus = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGuestAuctions() async {
    _isLoadingAuctions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        print('DEBUG [GuestController]: Loading MOCK auction data');
        _auctions = await mockDataSource.getGuestAuctionListings();
      } else {
        print('DEBUG [GuestController]: Loading DATABASE auction data');
        _auctions = await dataSource.getGuestAuctionListings();
      }
      _isLoadingAuctions = false;
      notifyListeners();
    } catch (e) {
      _isLoadingAuctions = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Toggle between mock and database data
  void toggleDataSource() {
    _useMockData = !_useMockData;
    print('DEBUG [GuestController]: Data source toggled to ${_useMockData ? "MOCK" : "DATABASE"}');
    notifyListeners();
    // Reload auctions with new data source
    loadGuestAuctions();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAccountStatus() {
    _accountStatus = null;
    _statusEmail = null;
    notifyListeners();
  }
}
