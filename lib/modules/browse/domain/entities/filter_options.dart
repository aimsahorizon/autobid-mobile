/// Static filter options and constants
/// Provides predefined values for dropdown filters
class FilterOptions {
  // Car makes (common brands in Philippines)
  static const List<String> makes = [
    'Toyota',
    'Honda',
    'Mitsubishi',
    'Nissan',
    'Ford',
    'Mazda',
    'Suzuki',
    'Hyundai',
    'Kia',
    'Isuzu',
    'Chevrolet',
    'Subaru',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Lexus',
    'Volvo',
    'Land Rover',
    'Jeep',
  ];

  // Transmission types
  static const List<String> transmissions = [
    'Manual',
    'Automatic',
    'CVT',
    'DCT',
    'AMT',
  ];

  // Fuel types
  static const List<String> fuelTypes = [
    'Gasoline',
    'Diesel',
    'Hybrid',
    'Electric',
    'Plug-in Hybrid',
  ];

  // Drive types
  static const List<String> driveTypes = [
    'FWD',
    '4WD',
    'AWD',
    'RWD',
  ];

  // Vehicle conditions
  static const List<String> conditions = [
    'Brand New',
    'Like New',
    'Excellent',
    'Good',
    'Fair',
    'Needs Work',
  ];

  // Common colors
  static const List<String> colors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Brown',
    'Beige',
    'Gold',
    'Green',
    'Orange',
    'Yellow',
    'Purple',
  ];

  // Philippines regions
  static const List<String> regions = [
    'NCR',
    'Region I - Ilocos',
    'Region II - Cagayan Valley',
    'Region III - Central Luzon',
    'Region IV-A - CALABARZON',
    'Region IV-B - MIMAROPA',
    'Region V - Bicol',
    'Region VI - Western Visayas',
    'Region VII - Central Visayas',
    'Region VIII - Eastern Visayas',
    'Region IX - Zamboanga Peninsula',
    'Region X - Northern Mindanao',
    'Region XI - Davao',
    'Region XII - SOCCSKSARGEN',
    'Region XIII - Caraga',
    'CAR - Cordillera',
    'BARMM',
  ];

  // Year ranges (last 30 years + upcoming year)
  static List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate(31, (index) => currentYear + 1 - index);
  }

  // Price ranges (in PHP)
  static const List<double> priceRanges = [
    100000,
    200000,
    300000,
    400000,
    500000,
    750000,
    1000000,
    1500000,
    2000000,
    3000000,
    5000000,
  ];

  // Mileage ranges (in kilometers)
  static const List<int> mileageRanges = [
    10000,
    20000,
    30000,
    50000,
    75000,
    100000,
    150000,
    200000,
    300000,
  ];
}
