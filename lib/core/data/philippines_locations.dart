/// Philippine provinces and cities data
/// Used for location selection in forms
class PhilippineLocations {
  // Map of province to list of cities/municipalities
  static const Map<String, List<String>> provinceCities = {
    'Metro Manila': [
      'Caloocan',
      'Las Piñas',
      'Makati',
      'Malabon',
      'Mandaluyong',
      'Manila',
      'Marikina',
      'Muntinlupa',
      'Navotas',
      'Parañaque',
      'Pasay',
      'Pasig',
      'Quezon City',
      'San Juan',
      'Taguig',
      'Valenzuela',
    ],
    'Cebu': [
      'Cebu City',
      'Lapu-Lapu City',
      'Mandaue City',
      'Talisay City',
      'Toledo City',
      'Bogo City',
      'Carcar City',
    ],
    'Davao del Sur': [
      'Davao City',
      'Digos City',
      'Bansalan',
      'Hagonoy',
      'Kiblawan',
      'Magsaysay',
      'Malalag',
    ],
    'Laguna': [
      'Calamba',
      'San Pablo',
      'Biñan',
      'Santa Rosa',
      'Cabuyao',
      'San Pedro',
      'Los Baños',
    ],
    'Cavite': [
      'Bacoor',
      'Cavite City',
      'Dasmariñas',
      'General Trias',
      'Imus',
      'Tagaytay',
      'Trece Martires',
    ],
    'Bulacan': [
      'Malolos',
      'Meycauayan',
      'San Jose del Monte',
      'Marilao',
      'Santa Maria',
      'Bocaue',
      'Balagtas',
    ],
    'Pampanga': [
      'Angeles City',
      'San Fernando',
      'Mabalacat',
      'Porac',
      'Guagua',
      'Apalit',
      'Mexico',
    ],
    'Rizal': [
      'Antipolo',
      'Cainta',
      'Taytay',
      'Binangonan',
      'San Mateo',
      'Rodriguez',
      'Angono',
    ],
  };

  /// Get all provinces
  static List<String> get provinces => provinceCities.keys.toList()..sort();

  /// Get cities for a province
  static List<String> getCities(String province) {
    return provinceCities[province] ?? [];
  }
}
