import 'package:flutter/material.dart';
import '../../domain/entities/account_status_entity.dart';
import '../../domain/usecases/check_account_status_usecase.dart';
import '../../domain/usecases/get_guest_auction_listings_usecase.dart';

/// Controller for guest mode operations
/// Refactored to use Clean Architecture with UseCases
class GuestController extends ChangeNotifier {
  final CheckAccountStatusUseCase _checkAccountStatusUseCase;
  final GetGuestAuctionListingsUseCase _getGuestAuctionListingsUseCase;

  GuestController({
    required CheckAccountStatusUseCase checkAccountStatusUseCase,
    required GetGuestAuctionListingsUseCase getGuestAuctionListingsUseCase,
  }) : _checkAccountStatusUseCase = checkAccountStatusUseCase,
       _getGuestAuctionListingsUseCase = getGuestAuctionListingsUseCase;

  int _currentTabIndex = 0;
  bool _isLoadingStatus = false;
  bool _isLoadingAuctions = false;
  AccountStatusEntity? _accountStatus;
  List<Map<String, dynamic>> _auctions = [];
  String? _errorMessage;
  String? _statusEmail;

  int get currentTabIndex => _currentTabIndex;
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isLoadingAuctions => _isLoadingAuctions;
  AccountStatusEntity? get accountStatus => _accountStatus;
  List<Map<String, dynamic>> get auctions => _auctions;
  String? get errorMessage => _errorMessage;
  String? get statusEmail => _statusEmail;

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
      // Use UseCase to check account status
      final result = await _checkAccountStatusUseCase(email);

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          _accountStatus = null;
        },
        (status) {
          _accountStatus = status;
          _errorMessage = null;
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  Future<void> loadGuestAuctions() async {
    _isLoadingAuctions = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('DEBUG [GuestController]: Loading guest auction listings');

      // Use UseCase to get auction listings
      final result = await _getGuestAuctionListingsUseCase();

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          _auctions = [];
        },
        (auctions) {
          _auctions = auctions;
          _errorMessage = null;
          print('DEBUG [GuestController]: Loaded ${auctions.length} auctions');
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _auctions = [];
    } finally {
      _isLoadingAuctions = false;
      notifyListeners();
    }
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
