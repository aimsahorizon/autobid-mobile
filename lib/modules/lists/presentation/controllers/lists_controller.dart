import 'package:flutter/material.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../../data/datasources/seller_listings_mock_datasource.dart';

class ListsController extends ChangeNotifier {
  final SellerListingsMockDataSource _dataSource;

  ListsController() : _dataSource = SellerListingsMockDataSource();

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
      _listings = await _dataSource.getAllListings();
    } catch (e) {
      _errorMessage = 'Failed to load listings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }
}
