import 'package:flutter/material.dart';
import '../../domain/entities/auction_entity.dart';
import '../../domain/entities/auction_filter.dart';
import '../../domain/repositories/auction_repository.dart';

class BrowseController extends ChangeNotifier {
  final AuctionRepository _repository;

  BrowseController(this._repository);

  List<AuctionEntity> _auctions = [];
  bool _isLoading = false;
  String? _errorMessage;
  AuctionFilter _currentFilter = const AuctionFilter();

  List<AuctionEntity> get auctions => _auctions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  AuctionFilter get currentFilter => _currentFilter;
  bool get hasActiveFilters => _currentFilter.hasActiveFilters;
  int get activeFilterCount => _currentFilter.activeFilterCount;

  Future<void> loadAuctions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auctions = await _repository.getActiveAuctions(filter: _currentFilter);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load auctions';
      _auctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply new filter and reload auctions
  Future<void> applyFilter(AuctionFilter filter) async {
    _currentFilter = filter;
    await loadAuctions();
  }

  /// Update filter and reload auctions
  Future<void> updateFilter({
    String? searchQuery,
    String? make,
    String? model,
    int? yearFrom,
    int? yearTo,
    double? priceMin,
    double? priceMax,
    String? transmission,
    String? fuelType,
    String? driveType,
    String? condition,
    int? maxMileage,
    String? exteriorColor,
    String? province,
    String? city,
    bool? endingSoon,
  }) async {
    _currentFilter = _currentFilter.copyWith(
      searchQuery: searchQuery,
      make: make,
      model: model,
      yearFrom: yearFrom,
      yearTo: yearTo,
      priceMin: priceMin,
      priceMax: priceMax,
      transmission: transmission,
      fuelType: fuelType,
      driveType: driveType,
      condition: condition,
      maxMileage: maxMileage,
      exteriorColor: exteriorColor,
      province: province,
      city: city,
      endingSoon: endingSoon,
    );
    await loadAuctions();
  }

  /// Clear all filters and reload
  Future<void> clearFilters() async {
    _currentFilter = const AuctionFilter();
    await loadAuctions();
  }

  /// Update search query only
  Future<void> updateSearchQuery(String query) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await loadAuctions();
  }

  Future<void> searchAuctions(String query) async {
    if (query.isEmpty) {
      await loadAuctions();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auctions = await _repository.searchAuctions(query);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to search auctions';
      _auctions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
