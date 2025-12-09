import 'package:flutter/material.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../data/datasources/seller_listings_mock_datasource.dart';
import '../../data/datasources/listing_supabase_datasource.dart';
import '../../../../app/core/config/supabase_config.dart';

/// Controller for managing seller listings across all tabs
/// Supports both mock and Supabase datasources
class ListsController extends ChangeNotifier {
  final SellerListingsMockDataSource? _mockDataSource;
  final ListingSupabaseDataSource? _supabaseDataSource;
  final bool _useMockData;

  /// Create controller with mock datasource
  ListsController.mock()
      : _mockDataSource = SellerListingsMockDataSource(),
        _supabaseDataSource = null,
        _useMockData = true;

  /// Create controller with Supabase datasource
  ListsController.supabase()
      : _mockDataSource = null,
        _supabaseDataSource = ListingSupabaseDataSource(SupabaseConfig.client),
        _useMockData = false;

  Map<ListingStatus, List<SellerListingEntity>> _listings = {};
  bool _isLoading = false;
  bool _isGridView = true;
  String? _errorMessage;

  Map<ListingStatus, List<SellerListingEntity>> get listings => _listings;
  bool get isLoading => _isLoading;
  bool get isGridView => _isGridView;
  String? get errorMessage => _errorMessage;

  List<SellerListingEntity> getListingsByStatus(ListingStatus status) =>
      _listings[status] ?? [];

  int getCountByStatus(ListingStatus status) =>
      _listings[status]?.length ?? 0;

  Future<void> loadListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        // Use mock datasource
        _listings = await _mockDataSource!.getAllListings();
      } else {
        // Use Supabase datasource - fetch from database
        _listings = await _loadFromSupabase();
      }
    } catch (e) {
      _errorMessage = 'Failed to load listings: $e';
      print('[ListsController] Error loading listings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load listings from Supabase, grouped by status
  Future<Map<ListingStatus, List<SellerListingEntity>>> _loadFromSupabase() async {
    final sellerId = SupabaseConfig.client.auth.currentUser?.id;
    if (sellerId == null) {
      return {}; // Return empty if not logged in
    }

    final Map<ListingStatus, List<SellerListingEntity>> result = {};

    // Fetch drafts (from listing_drafts table)
    try {
      final drafts = await _supabaseDataSource!.getSellerDrafts(sellerId);
      result[ListingStatus.draft] = drafts
          .map((draft) => SellerListingEntity(
                id: draft.id,
                imageUrl: draft.photoUrls?.values.firstOrNull?.firstOrNull ?? '',
                year: draft.year ?? 0,
                make: draft.brand ?? 'Unknown',
                model: draft.model ?? 'Unknown',
                status: ListingStatus.draft,
                startingPrice: draft.startingPrice ?? 0,
                totalBids: 0,
                watchersCount: 0,
                viewsCount: 0,
                createdAt: draft.lastSaved,
              ))
          .toList();
    } catch (e) {
      print('[ListsController] Error loading drafts: $e');
      result[ListingStatus.draft] = [];
    }

    // Fetch pending listings (waiting for admin approval)
    try {
      final pending = await _supabaseDataSource!.getPendingListings(sellerId);
      result[ListingStatus.pending] = pending
          .map((listing) => listing.toSellerListingEntity())
          .toList();
    } catch (e) {
      print('[ListsController] Error loading pending: $e');
      result[ListingStatus.pending] = [];
    }

    // Fetch approved listings (approved by admin, waiting to be made live)
    try {
      final approved = await _supabaseDataSource!.getApprovedListings(sellerId);
      result[ListingStatus.approved] = approved
          .map((listing) => listing.toSellerListingEntity())
          .toList();
    } catch (e) {
      print('[ListsController] Error loading approved: $e');
      result[ListingStatus.approved] = [];
    }

    // Fetch active listings (live auctions)
    try {
      final active = await _supabaseDataSource!.getActiveListings(sellerId);
      result[ListingStatus.active] = active
          .map((listing) => listing.toSellerListingEntity())
          .toList();
    } catch (e) {
      print('[ListsController] Error loading active: $e');
      result[ListingStatus.active] = [];
    }

    // Fetch ended listings (awaiting seller decision)
    try {
      final ended = await _supabaseDataSource!.getEndedListings(sellerId);
      result[ListingStatus.ended] = ended
          .map((listing) => listing.toSellerListingEntity())
          .toList();
    } catch (e) {
      print('[ListsController] Error loading ended: $e');
      result[ListingStatus.ended] = [];
    }

    // Fetch cancelled/rejected listings
    try {
      final cancelled = await _supabaseDataSource!.getCancelledListings(sellerId);
      result[ListingStatus.cancelled] = cancelled
          .map((listing) => listing.toSellerListingEntity())
          .toList();
    } catch (e) {
      print('[ListsController] Error loading cancelled: $e');
      result[ListingStatus.cancelled] = [];
    }

    return result;
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }
}
