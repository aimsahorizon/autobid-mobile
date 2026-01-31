import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/usecases/get_seller_listings_usecase.dart';
import '../../domain/usecases/stream_seller_listings_usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Controller for managing seller listings across all tabs
class ListsController extends ChangeNotifier {
  final GetSellerListingsUseCase _getSellerListingsUseCase;
  final StreamSellerListingsUseCase _streamSellerListingsUseCase;
  final AuthRepository _authRepository;

  ListsController(
    this._getSellerListingsUseCase,
    this._streamSellerListingsUseCase,
    this._authRepository,
  );

  Map<ListingStatus, List<SellerListingEntity>> _listings = {};
  bool _isLoading = false;
  bool _isGridView = true;
  String? _errorMessage;
  StreamSubscription? _listingsSubscription;

  Map<ListingStatus, List<SellerListingEntity>> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isGridView => _isGridView;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _listingsSubscription?.cancel();
    super.dispose();
  }

  List<SellerListingEntity> getListingsByStatus(ListingStatus status) =>
      _listings[status] ?? [];

  int getCountByStatus(ListingStatus status) => _listings[status]?.length ?? 0;

  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current user ID
      final userResult = await _authRepository.getCurrentUser();
      final userId = userResult.fold((l) => null, (r) => r?.id);

      if (userId == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch all listings using UseCase
      final result = await _getSellerListingsUseCase.call(userId);

      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (listingsMap) {
          _listings = listingsMap;
          // Start subscription if not already active
          if (_listingsSubscription == null) {
            _subscribeToUpdates(userId);
          }
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to load listings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToUpdates(String userId) {
    _listingsSubscription?.cancel();
    _listingsSubscription = _streamSellerListingsUseCase(userId).listen(
      (_) {
        // Reload listings quietly on update
        _reloadListingsQuietly(userId);
      },
      onError: (e) {
        debugPrint('Realtime listing subscription error: $e');
      },
    );
  }

  Future<void> _reloadListingsQuietly(String userId) async {
    try {
      final result = await _getSellerListingsUseCase.call(userId);
      result.fold(
        (failure) =>
            debugPrint('Failed to reload listings: ${failure.message}'),
        (listingsMap) {
          _listings = listingsMap;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to reload listings: $e');
    }
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  /// Convenience factory for backward compatibility if needed during migration
  /// (Should be replaced by sl() in UI)
  factory ListsController.supabase() {
    throw UnsupportedError(
      'Use dependency injection via GetIt (sl<ListsController>())',
    );
  }
}
