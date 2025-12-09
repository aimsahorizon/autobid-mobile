import 'package:flutter/foundation.dart';
import '../../domain/entities/admin_listing_entity.dart';
import '../../data/datasources/admin_supabase_datasource.dart';

/// Admin controller for managing listings and dashboard
class AdminController extends ChangeNotifier {
  final AdminSupabaseDataSource _dataSource;

  AdminStatsEntity? _stats;
  List<AdminListingEntity> _pendingListings = [];
  List<AdminListingEntity> _allListings = [];
  bool _isLoading = false;
  String? _error;
  String _selectedStatus = 'pending_approval';

  AdminController(this._dataSource);

  // Getters
  AdminStatsEntity? get stats => _stats;
  List<AdminListingEntity> get pendingListings => _pendingListings;
  List<AdminListingEntity> get allListings => _allListings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;

  /// Load admin dashboard data
  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _dataSource.getAdminStats();
      _pendingListings = await _dataSource.getPendingListings();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load listings by status
  Future<void> loadListingsByStatus(String status) async {
    _selectedStatus = status;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allListings = await _dataSource.getListingsByStatus(status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a listing
  Future<bool> approveListing(String auctionId, {String? notes}) async {
    try {
      await _dataSource.approveListing(auctionId, notes: notes);

      // Reload data
      await loadDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject a listing
  Future<bool> rejectListing(String auctionId, String reason) async {
    try {
      await _dataSource.rejectListing(auctionId, reason);

      // Reload data
      await loadDashboard();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Change listing status
  Future<bool> changeStatus(String auctionId, String newStatus) async {
    try {
      await _dataSource.changeListingStatus(auctionId, newStatus);

      // Reload current view
      if (_selectedStatus == 'pending_approval') {
        await loadDashboard();
      } else {
        await loadListingsByStatus(_selectedStatus);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresh current view
  Future<void> refresh() async {
    if (_selectedStatus == 'pending_approval') {
      await loadDashboard();
    } else {
      await loadListingsByStatus(_selectedStatus);
    }
  }
}
