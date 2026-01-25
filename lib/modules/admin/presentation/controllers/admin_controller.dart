import 'package:flutter/foundation.dart';
import '../../domain/entities/admin_listing_entity.dart';
import '../../domain/entities/admin_enums.dart';
import '../../data/datasources/admin_supabase_datasource.dart';

/// Admin controller for managing listings and dashboard.
/// 
/// REFERENCE FOR NEXT.js:
/// This controller coordinates admin actions. In Next.js, these methods 
/// should be converted to Server Actions or API routes with proper 
/// middleware-based role checks (Super Admin/Moderator).
class AdminController extends ChangeNotifier {
  final AdminSupabaseDataSource _dataSource;

  AdminStatsEntity? _stats;
  List<AdminListingEntity> _pendingListings = [];
  List<AdminListingEntity> _allListings = [];
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String? _error;
  
  // Use Enum for type safety and clarity
  AdminListingStatus _selectedStatus = AdminListingStatus.pendingApproval;

  AdminController(this._dataSource);

  // Getters
  AdminStatsEntity? get stats => _stats;
  List<AdminListingEntity> get pendingListings => _pendingListings;
  List<AdminListingEntity> get allListings => _allListings;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Current filter for listings page
  AdminListingStatus get selectedStatus => _selectedStatus;

  /// Load admin dashboard data (Total auctions, active users, etc)
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

  /// Load listings by status (Filtered view)
  Future<void> loadListingsByStatus(AdminListingStatus status) async {
    _selectedStatus = status;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allListings = await _dataSource.getListingsByStatus(status.dbValue);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve a listing (Moves it from 'pending_approval' to 'scheduled')
  Future<bool> approveListing(String auctionId, {String? notes}) async {
    try {
      await _dataSource.approveListing(auctionId, notes: notes);

      // Refresh data
      await loadDashboard();
      await loadListingsByStatus(_selectedStatus);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Reject a listing (Moves it to 'cancelled' with a reason)
  Future<bool> rejectListing(String auctionId, String reason) async {
    try {
      await _dataSource.rejectListing(auctionId, reason);

      // Refresh data
      await loadDashboard();
      await loadListingsByStatus(_selectedStatus);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Change listing status manually
  Future<bool> changeStatus(String auctionId, AdminListingStatus newStatus) async {
    try {
      await _dataSource.changeListingStatus(auctionId, newStatus.dbValue);

      // Refresh current view
      if (_selectedStatus == AdminListingStatus.pendingApproval) {
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

  /// Load all users for the management tab
  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _dataSource.getAllUsers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh the current active view
  Future<void> refresh() async {
    if (_selectedStatus == AdminListingStatus.pendingApproval) {
      await loadDashboard();
    } else {
      await loadListingsByStatus(_selectedStatus);
    }
  }
}