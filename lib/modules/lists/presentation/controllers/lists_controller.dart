import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/usecases/get_seller_listings_usecase.dart';
import '../../domain/usecases/stream_seller_listings_usecase.dart';
import '../../domain/usecases/submission_usecases.dart';
import '../../domain/usecases/delete_listing_usecase.dart';
import '../../domain/usecases/manage_invites_usecases.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../browse/data/datasources/invites_supabase_datasource.dart';

/// Controller for managing seller listings across all tabs
class ListsController extends ChangeNotifier {
  final GetSellerListingsUseCase _getSellerListingsUseCase;
  final StreamSellerListingsUseCase _streamSellerListingsUseCase;
  final AuthRepository _authRepository;
  final DeleteDraftUseCase _deleteDraftUseCase;
  final DeleteListingUseCase _deleteListingUseCase;
  final CancelListingUseCase _cancelListingUseCase;

  // Invite Management
  final GetAuctionInvitesUseCase? _getAuctionInvitesUseCase;
  final InviteUserUseCase? _inviteUserUseCase;
  final DeleteInviteUseCase? _deleteInviteUseCase;

  ListsController(
    this._getSellerListingsUseCase,
    this._streamSellerListingsUseCase,
    this._authRepository,
    this._deleteDraftUseCase,
    this._deleteListingUseCase,
    this._cancelListingUseCase, {
    GetAuctionInvitesUseCase? getAuctionInvitesUseCase,
    InviteUserUseCase? inviteUserUseCase,
    DeleteInviteUseCase? deleteInviteUseCase,
  }) : _getAuctionInvitesUseCase = getAuctionInvitesUseCase,
       _inviteUserUseCase = inviteUserUseCase,
       _deleteInviteUseCase = deleteInviteUseCase;

  Map<ListingStatus, List<SellerListingEntity>> _listings = {};
  bool _isLoading = false;
  bool _isGridView = true;
  String? _errorMessage;
  StreamSubscription? _listingsSubscription;
  Timer? _autoRefreshTimer;

  // Selection state
  final Set<String> _selectedListingIds = {};
  bool _isSelectionMode = false;

  // View state
  bool _showAll = false;

  // Invite state
  List<Map<String, dynamic>> _currentAuctionInvites = [];
  bool _isInvitesLoading = false;
  StreamSubscription<List<Map<String, dynamic>>>? _invitesSubscription;
  String? _streamingAuctionId;

  Map<ListingStatus, List<SellerListingEntity>> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isGridView => _isGridView;
  String? get errorMessage => _errorMessage;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedListingIds => _selectedListingIds;
  int get selectedCount => _selectedListingIds.length;
  bool get showAll => _showAll;

  List<Map<String, dynamic>> get currentAuctionInvites =>
      _currentAuctionInvites;
  bool get isInvitesLoading => _isInvitesLoading;

  @override
  void dispose() {
    _isDisposed = true;
    _listingsSubscription?.cancel();
    _autoRefreshTimer?.cancel();
    _invitesSubscription?.cancel();
    super.dispose();
  }

  void toggleShowAll() {
    _showAll = !_showAll;
    notifyListeners();
  }

  // Selection methods
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedListingIds.clear();
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedListingIds.contains(id)) {
      _selectedListingIds.remove(id);
      if (_selectedListingIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedListingIds.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedListingIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  void selectAll(List<SellerListingEntity> currentList) {
    if (_selectedListingIds.length == currentList.length) {
      _selectedListingIds.clear();
    } else {
      _selectedListingIds.addAll(currentList.map((e) => e.id));
    }
    notifyListeners();
  }

  // Bulk Delete
  Future<void> deleteSelected() async {
    if (_selectedListingIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Find all selected listings to check their status
      final allListings = _listings.values.expand((l) => l).toList();
      final selectedListings = allListings
          .where((l) => _selectedListingIds.contains(l.id))
          .toList();

      for (final listing in selectedListings) {
        try {
          if (listing.status == ListingStatus.draft) {
            await _deleteDraftUseCase(listing.id);
          } else if (listing.status == ListingStatus.cancelled ||
              listing.status == ListingStatus.rejected ||
              listing.status == ListingStatus.ended ||
              listing.status == ListingStatus.sold || // Cleanup old sold
              listing.status == ListingStatus.dealFailed) {
            await _deleteListingUseCase(listing.id);
          } else {
            // Active, Pending, Scheduled -> Soft Cancel
            await _cancelListingUseCase(listing.id);
          }
        } catch (e) {
          debugPrint('Failed to delete/cancel listing ${listing.id}: $e');
          // Continue with others
        }
      }

      _selectedListingIds.clear();
      _isSelectionMode = false;

      // Reload happens via stream automatically usually, but force refresh to be sure
      // Get current user ID
      final userResult = await _authRepository.getCurrentUser();
      final userId = userResult.fold((l) => null, (r) => r?.id);
      if (userId != null) {
        await _reloadListingsQuietly(userId);
      }
    } catch (e) {
      _errorMessage = 'Failed to delete selected items';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<SellerListingEntity> getListingsByStatus(ListingStatus status) =>
      _listings[status] ?? [];

  int getCountByStatus(ListingStatus status) => _listings[status]?.length ?? 0;

  Future<void> loadListings({bool isBackground = false}) async {
    if (!isBackground) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Get current user ID
      final userResult = await _authRepository.getCurrentUser();
      final userId = userResult.fold((l) => null, (r) => r?.id);

      if (userId == null) {
        if (!isBackground) {
          _errorMessage = 'User not authenticated';
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Start subscription if not already active
      if (_listingsSubscription == null) {
        _subscribeToUpdates(userId);
      }
      _ensureAutoRefresh();

      // Fetch all listings using UseCase
      final result = await _getSellerListingsUseCase.call(userId);

      result.fold(
        (failure) {
          if (!isBackground) {
            _errorMessage = failure.message;
          }
        },
        (listingsMap) {
          _listings = listingsMap.map(
            (status, items) => MapEntry(status, _dedupeByListingId(items)),
          );
          _errorMessage = null;
        },
      );
    } catch (e) {
      if (!isBackground) {
        _errorMessage = 'Failed to load listings: $e';
      }
    } finally {
      if (!isBackground) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void _subscribeToUpdates(String userId) {
    _listingsSubscription?.cancel();
    _listingsSubscription = null;
    _listingsSubscription = _streamSellerListingsUseCase(userId).listen(
      (_) {
        // Reload listings quietly on update
        loadListings(isBackground: true);
      },
      onError: (e) {
        debugPrint('Realtime listing subscription error: $e');
        // Re-subscribe after error
        _listingsSubscription?.cancel();
        _listingsSubscription = null;
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isDisposed) _subscribeToUpdates(userId);
        });
      },
      onDone: () {
        debugPrint('Realtime listing subscription completed, re-subscribing');
        _listingsSubscription = null;
        if (!_isDisposed) _subscribeToUpdates(userId);
      },
    );
  }

  bool _isDisposed = false;

  void _ensureAutoRefresh() {
    if (_autoRefreshTimer != null) {
      return;
    }

    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_isLoading) {
        loadListings(isBackground: true);
      }
    });
  }

  Future<void> _reloadListingsQuietly(String userId) async {
    await loadListings(isBackground: true);
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  List<SellerListingEntity> _dedupeByListingId(
    List<SellerListingEntity> items,
  ) {
    final map = <String, SellerListingEntity>{};
    for (final item in items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  // ============================================================================
  // INVITE MANAGEMENT
  // ============================================================================

  Future<void> loadAuctionInvites(String auctionId) async {
    if (_getAuctionInvitesUseCase == null) return;

    _isInvitesLoading = true;
    notifyListeners();

    final result = await _getAuctionInvitesUseCase.call(auctionId);
    result.fold(
      (failure) => _errorMessage = failure.message,
      (invites) => _currentAuctionInvites = invites,
    );

    _isInvitesLoading = false;
    notifyListeners();
  }

  void startAuctionInvitesStream(String auctionId) {
    if (_streamingAuctionId == auctionId && _invitesSubscription != null) {
      return;
    }

    _invitesSubscription?.cancel();
    _streamingAuctionId = auctionId;
    _isInvitesLoading = true;
    notifyListeners();

    final invitesDatasource = GetIt.instance<InvitesSupabaseDatasource>();
    _invitesSubscription = invitesDatasource
        .streamAuctionInvites(auctionId)
        .listen(
          (invites) {
            _currentAuctionInvites = List<Map<String, dynamic>>.from(invites);
            _isInvitesLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _isInvitesLoading = false;
            _errorMessage = 'Failed to stream invites: $error';
            notifyListeners();
          },
        );
  }

  void stopAuctionInvitesStream(String auctionId) {
    if (_streamingAuctionId != auctionId) {
      return;
    }

    _invitesSubscription?.cancel();
    _invitesSubscription = null;
    _streamingAuctionId = null;
  }

  Future<bool> inviteUser({
    required String auctionId,
    required String identifier,
    required String type,
  }) async {
    if (_inviteUserUseCase == null) return false;

    _isInvitesLoading = true;
    notifyListeners();

    final result = await _inviteUserUseCase.call(
      auctionId: auctionId,
      identifier: identifier,
      type: type,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isInvitesLoading = false;
        notifyListeners();
        return false;
      },
      (inviteId) async {
        await loadAuctionInvites(auctionId);
        return true;
      },
    );
  }

  Future<bool> deleteInvite(String inviteId, String auctionId) async {
    if (_deleteInviteUseCase == null) return false;

    _isInvitesLoading = true;
    notifyListeners();

    final result = await _deleteInviteUseCase.call(inviteId);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isInvitesLoading = false;
        notifyListeners();
        return false;
      },
      (_) async {
        await loadAuctionInvites(auctionId);
        return true;
      },
    );
  }

  /// Convenience factory for backward compatibility if needed during migration
  /// (Should be replaced by sl() in UI)
  factory ListsController.supabase() {
    throw UnsupportedError(
      'Use dependency injection via GetIt (sl<ListsController>())',
    );
  }
}
