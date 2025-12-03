/// Filter entity for auction browsing
/// Encapsulates all filter criteria for searching and filtering auctions
class AuctionFilter {
  // Search query
  final String? searchQuery;

  // Car basics
  final String? make;
  final String? model;
  final int? yearFrom;
  final int? yearTo;

  // Price range
  final double? priceMin;
  final double? priceMax;

  // Mechanical
  final String? transmission;
  final String? fuelType;
  final String? driveType;

  // Condition
  final String? condition;
  final int? maxMileage;

  // Exterior
  final String? exteriorColor;

  // Location
  final String? province;
  final String? city;

  // Auction timing
  final bool? endingSoon; // Within 24 hours

  const AuctionFilter({
    this.searchQuery,
    this.make,
    this.model,
    this.yearFrom,
    this.yearTo,
    this.priceMin,
    this.priceMax,
    this.transmission,
    this.fuelType,
    this.driveType,
    this.condition,
    this.maxMileage,
    this.exteriorColor,
    this.province,
    this.city,
    this.endingSoon,
  });

  /// Create empty filter (no filtering)
  const AuctionFilter.empty()
      : searchQuery = null,
        make = null,
        model = null,
        yearFrom = null,
        yearTo = null,
        priceMin = null,
        priceMax = null,
        transmission = null,
        fuelType = null,
        driveType = null,
        condition = null,
        maxMileage = null,
        exteriorColor = null,
        province = null,
        city = null,
        endingSoon = null;

  /// Copy with updated values
  AuctionFilter copyWith({
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
  }) {
    return AuctionFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      make: make ?? this.make,
      model: model ?? this.model,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      driveType: driveType ?? this.driveType,
      condition: condition ?? this.condition,
      maxMileage: maxMileage ?? this.maxMileage,
      exteriorColor: exteriorColor ?? this.exteriorColor,
      province: province ?? this.province,
      city: city ?? this.city,
      endingSoon: endingSoon ?? this.endingSoon,
    );
  }

  /// Clear specific filter
  AuctionFilter clearFilter(String filterKey) {
    switch (filterKey) {
      case 'searchQuery':
        return copyWith(searchQuery: '');
      case 'make':
        return copyWith(make: '');
      case 'model':
        return copyWith(model: '');
      case 'year':
        return AuctionFilter(
          searchQuery: searchQuery,
          make: make,
          model: model,
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
      case 'price':
        return AuctionFilter(
          searchQuery: searchQuery,
          make: make,
          model: model,
          yearFrom: yearFrom,
          yearTo: yearTo,
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
      default:
        return this;
    }
  }

  /// Check if any filter is active
  bool get hasActiveFilters {
    return searchQuery != null && searchQuery!.isNotEmpty ||
        make != null ||
        model != null ||
        yearFrom != null ||
        yearTo != null ||
        priceMin != null ||
        priceMax != null ||
        transmission != null ||
        fuelType != null ||
        driveType != null ||
        condition != null ||
        maxMileage != null ||
        exteriorColor != null ||
        province != null ||
        city != null ||
        endingSoon != null;
  }

  /// Count active filters
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (make != null) count++;
    if (model != null) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (priceMin != null || priceMax != null) count++;
    if (transmission != null) count++;
    if (fuelType != null) count++;
    if (driveType != null) count++;
    if (condition != null) count++;
    if (maxMileage != null) count++;
    if (exteriorColor != null) count++;
    if (province != null) count++;
    if (city != null) count++;
    if (endingSoon == true) count++;
    return count;
  }
}
