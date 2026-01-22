// Mock Philippine address data for KYC registration
// In production, this should be fetched from an API or database

class PhilippineAddressData {
  static final Map<String, List<String>> _regionProvinces = {
    'NCR (National Capital Region)': ['Metro Manila'],
    'Region I (Ilocos Region)': ['Ilocos Norte', 'Ilocos Sur', 'La Union', 'Pangasinan'],
    'Region II (Cagayan Valley)': ['Batanes', 'Cagayan', 'Isabela', 'Nueva Vizcaya', 'Quirino'],
    'Region III (Central Luzon)': ['Aurora', 'Bataan', 'Bulacan', 'Nueva Ecija', 'Pampanga', 'Tarlac', 'Zambales'],
    'Region IV-A (CALABARZON)': ['Batangas', 'Cavite', 'Laguna', 'Quezon', 'Rizal'],
    'Region V (Bicol Region)': ['Albay', 'Camarines Norte', 'Camarines Sur', 'Catanduanes', 'Masbate', 'Sorsogon'],
    'Region VI (Western Visayas)': ['Aklan', 'Antique', 'Capiz', 'Guimaras', 'Iloilo', 'Negros Occidental'],
    'Region VII (Central Visayas)': ['Bohol', 'Cebu', 'Negros Oriental', 'Siquijor'],
    'Region VIII (Eastern Visayas)': ['Biliran', 'Eastern Samar', 'Leyte', 'Northern Samar', 'Samar', 'Southern Leyte'],
    'Region IX (Zamboanga Peninsula)': ['Zamboanga del Norte', 'Zamboanga del Sur', 'Zamboanga Sibugay'],
    'Region X (Northern Mindanao)': ['Bukidnon', 'Camiguin', 'Lanao del Norte', 'Misamis Occidental', 'Misamis Oriental'],
    'Region XI (Davao Region)': ['Davao de Oro', 'Davao del Norte', 'Davao del Sur', 'Davao Occidental', 'Davao Oriental'],
    'Region XII (SOCCSKSARGEN)': ['Cotabato', 'Sarangani', 'South Cotabato', 'Sultan Kudarat'],
    'Region XIII (Caraga)': ['Agusan del Norte', 'Agusan del Sur', 'Dinagat Islands', 'Surigao del Norte', 'Surigao del Sur'],
    'CAR (Cordillera Administrative Region)': ['Abra', 'Apayao', 'Benguet', 'Ifugao', 'Kalinga', 'Mountain Province'],
    'BARMM (Bangsamoro)': ['Basilan', 'Lanao del Sur', 'Maguindanao', 'Sulu', 'Tawi-Tawi'],
  };

  static final Map<String, List<String>> _provinceCities = {
    'Metro Manila': [
      'Caloocan', 'Las Piñas', 'Makati', 'Malabon', 'Mandaluyong', 'Manila',
      'Marikina', 'Muntinlupa', 'Navotas', 'Parañaque', 'Pasay', 'Pasig',
      'Pateros', 'Quezon City', 'San Juan', 'Taguig', 'Valenzuela'
    ],
    'Cebu': [
      'Cebu City', 'Mandaue City', 'Lapu-Lapu City', 'Bogo City', 'Carcar City',
      'Danao City', 'Naga City', 'Talisay City', 'Toledo City'
    ],
    'Laguna': [
      'Biñan', 'Cabuyao', 'Calamba', 'San Pablo', 'San Pedro', 'Santa Rosa',
      'Alaminos', 'Bay', 'Calauan', 'Cavinti'
    ],
    'Cavite': [
      'Bacoor', 'Cavite City', 'Dasmariñas', 'General Trias', 'Imus', 'Tagaytay',
      'Trece Martires', 'Alfonso', 'Amadeo', 'Carmona'
    ],
    'Bulacan': [
      'Malolos', 'Meycauayan', 'San Jose del Monte', 'Angat', 'Balagtas',
      'Baliuag', 'Bocaue', 'Bulakan', 'Bustos', 'Calumpit'
    ],
    // Add more as needed - this is mock data
  };

  static final Map<String, List<String>> _cityBarangays = {
    'Quezon City': [
      'Bagong Pag-asa', 'Bahay Toro', 'Balingasa', 'Batasan Hills', 'Blue Ridge A',
      'Commonwealth', 'Fairview', 'Kalusugan', 'Kamuning', 'La Loma',
      'Malaya', 'Mariana', 'New Era', 'Old Capitol Site', 'Paligsahan',
      'San Agustin', 'Santo Domingo', 'Tatalon', 'Teachers Village', 'U.P. Campus'
    ],
    'Makati': [
      'Bangkal', 'Bel-Air', 'Cembo', 'Comembo', 'Dasmariñas', 'Forbes Park',
      'Guadalupe Nuevo', 'Guadalupe Viejo', 'Kasilawan', 'La Paz',
      'Magallanes', 'Olympia', 'Palanan', 'Pembo', 'Pinagkaisahan',
      'Pio del Pilar', 'Poblacion', 'Rizal', 'San Antonio', 'San Lorenzo'
    ],
    'Manila': [
      'Binondo', 'Ermita', 'Intramuros', 'Malate', 'Paco', 'Pandacan',
      'Port Area', 'Quiapo', 'Sampaloc', 'San Andres', 'San Miguel',
      'San Nicolas', 'Santa Ana', 'Santa Cruz', 'Santa Mesa', 'Tondo'
    ],
    'Cebu City': [
      'Apas', 'Banilad', 'Basak San Nicolas', 'Busay', 'Guadalupe', 'Kasambagan',
      'Lahug', 'Mabolo', 'Pardo', 'Pit-os', 'Talamban', 'Tisa'
    ],
    // Add more as needed - this is mock data
  };

  static List<String> getRegions() {
    return _regionProvinces.keys.toList()..sort();
  }

  static List<String> getProvinces(String region) {
    return _regionProvinces[region] ?? [];
  }

  static List<String> getCities(String province) {
    final cities = _provinceCities[province];
    if (cities != null) {
      return cities;
    }
    // Return mock cities if not in our data
    return ['$province City', '$province Capital', 'San Jose', 'Santa Cruz'];
  }

  static List<String> getBarangays(String city) {
    final barangays = _cityBarangays[city];
    if (barangays != null) {
      return barangays;
    }
    // Return mock barangays if not in our data
    return [
      'Poblacion', 'San Isidro', 'San Jose', 'San Juan',
      'Santa Cruz', 'Santo Niño', 'Barangay 1', 'Barangay 2'
    ];
  }
}
