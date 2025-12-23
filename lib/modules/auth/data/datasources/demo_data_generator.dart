import 'dart:math';

/// Generates randomized demo data for KYC registration auto-fill
class DemoDataGenerator {
  static final _random = Random();

  // Filipino first names
  static const _firstNames = [
    'Juan', 'Maria', 'Jose', 'Ana', 'Pedro', 'Rosa', 'Miguel', 'Carmen',
    'Francisco', 'Luz', 'Antonio', 'Teresa', 'Manuel', 'Elena', 'Carlos',
    'Sofia', 'Fernando', 'Isabel', 'Ricardo', 'Beatriz', 'Andres', 'Gloria',
    'Luis', 'Patricia', 'Ramon', 'Victoria', 'Gabriel', 'Cristina', 'Rafael',
    'Margarita', 'Diego', 'Angelica', 'Roberto', 'Cecilia', 'Eduardo'
  ];

  // Filipino middle names
  static const _middleNames = [
    'Cruz', 'Santos', 'Reyes', 'Garcia', 'Ramos', 'Torres', 'Flores',
    'Gonzales', 'Mendoza', 'Lopez', 'Aquino', 'Bautista', 'Castro', 'Diaz',
    'Rivera', 'Fernandez', 'Morales', 'Villanueva', 'Domingo', 'Santiago'
  ];

  // Filipino last names
  static const _lastNames = [
    'Dela Cruz', 'Santos', 'Reyes', 'Garcia', 'Ramos', 'Torres', 'Flores',
    'Gonzales', 'Mendoza', 'Lopez', 'Aquino', 'Bautista', 'Castro', 'Diaz',
    'Rivera', 'Fernandez', 'Morales', 'Villanueva', 'Domingo', 'Santiago',
    'Perez', 'Martinez', 'Soriano', 'Jimenez', 'Alvarez', 'Velasco'
  ];

  // Sex options
  static const _sexOptions = ['Male', 'Female'];

  // Regions in the Philippines
  static const _regions = [
    'NCR - National Capital Region',
    'Region I - Ilocos Region',
    'Region III - Central Luzon',
    'Region IV-A - CALABARZON',
    'Region VII - Central Visayas',
    'Region X - Northern Mindanao',
  ];

  // Sample provinces by region
  static const _provincesByRegion = {
    'NCR - National Capital Region': ['Metro Manila'],
    'Region I - Ilocos Region': ['Pangasinan', 'La Union', 'Ilocos Norte', 'Ilocos Sur'],
    'Region III - Central Luzon': ['Bulacan', 'Pampanga', 'Tarlac', 'Nueva Ecija'],
    'Region IV-A - CALABARZON': ['Cavite', 'Laguna', 'Batangas', 'Rizal', 'Quezon'],
    'Region VII - Central Visayas': ['Cebu', 'Bohol', 'Negros Oriental', 'Siquijor'],
    'Region X - Northern Mindanao': ['Bukidnon', 'Camiguin', 'Lanao del Norte', 'Misamis Occidental'],
  };

  // Sample cities by province
  static const _citiesByProvince = {
    'Metro Manila': ['Manila', 'Quezon City', 'Makati', 'Pasig', 'Taguig', 'Pasay'],
    'Pangasinan': ['Dagupan', 'San Carlos', 'Urdaneta', 'Alaminos'],
    'Bulacan': ['Malolos', 'Meycauayan', 'San Jose del Monte', 'Marilao'],
    'Cavite': ['Bacoor', 'Dasmariñas', 'Imus', 'Tagaytay', 'Trece Martires'],
    'Cebu': ['Cebu City', 'Mandaue', 'Lapu-Lapu', 'Talisay', 'Toledo'],
    'Bukidnon': ['Malaybalay', 'Valencia', 'Maramag', 'Manolo Fortich'],
  };

  // Sample barangays
  static const _barangays = [
    'Poblacion', 'San Isidro', 'Santa Cruz', 'San Antonio', 'Barangay 1',
    'Barangay 2', 'San Jose', 'San Miguel', 'Santa Maria', 'Santo Niño',
    'San Pedro', 'San Juan', 'Santa Rosa', 'San Francisco', 'San Vicente'
  ];

  // Sample street names
  static const _streets = [
    'Rizal Street', 'Bonifacio Avenue', 'Mabini Street', 'Del Pilar Avenue',
    'Luna Street', 'Quezon Boulevard', 'Roxas Avenue', 'Burgos Street',
    'Aguinaldo Highway', 'Evangelista Street', 'Gomez Street', 'Zamora Street',
    'Lacson Street', 'Malvar Avenue', 'Guerrero Street'
  ];

  /// Generate random first name
  static String generateFirstName() {
    return _firstNames[_random.nextInt(_firstNames.length)];
  }

  /// Generate random middle name
  static String generateMiddleName() {
    return _middleNames[_random.nextInt(_middleNames.length)];
  }

  /// Generate random last name
  static String generateLastName() {
    return _lastNames[_random.nextInt(_lastNames.length)];
  }

  /// Generate random username based on name
  static String generateUsername(String firstName, String lastName) {
    final cleanFirst = firstName.toLowerCase().replaceAll(' ', '');
    final cleanLast = lastName.toLowerCase().replaceAll(' ', '');
    final number = _random.nextInt(9999).toString().padLeft(4, '0');
    return '$cleanFirst$cleanLast$number';
  }

  /// Generate random date of birth (age between 18-65 years)
  static DateTime generateDateOfBirth() {
    final now = DateTime.now();
    final minAge = 18;
    final maxAge = 65;
    final age = minAge + _random.nextInt(maxAge - minAge);
    final year = now.year - age;
    final month = 1 + _random.nextInt(12);
    final day = 1 + _random.nextInt(28); // Safe for all months
    return DateTime(year, month, day);
  }

  /// Generate random sex
  static String generateSex() {
    return _sexOptions[_random.nextInt(_sexOptions.length)];
  }

  /// Generate random national ID number (format: 1234-5678-9012-3456)
  static String generateNationalIdNumber() {
    final part1 = _random.nextInt(9999).toString().padLeft(4, '0');
    final part2 = _random.nextInt(9999).toString().padLeft(4, '0');
    final part3 = _random.nextInt(9999).toString().padLeft(4, '0');
    final part4 = _random.nextInt(9999).toString().padLeft(4, '0');
    return '$part1-$part2-$part3-$part4';
  }

  /// Generate random region
  static String generateRegion() {
    return _regions[_random.nextInt(_regions.length)];
  }

  /// Generate random province for given region
  static String generateProvince(String region) {
    final provinces = _provincesByRegion[region] ?? ['Metro Manila'];
    return provinces[_random.nextInt(provinces.length)];
  }

  /// Generate random city for given province
  static String generateCity(String province) {
    final cities = _citiesByProvince[province] ?? ['City Center'];
    return cities[_random.nextInt(cities.length)];
  }

  /// Generate random barangay
  static String generateBarangay() {
    return _barangays[_random.nextInt(_barangays.length)];
  }

  /// Generate random street with number
  static String generateStreet() {
    final streetName = _streets[_random.nextInt(_streets.length)];
    final number = _random.nextInt(999) + 1;
    return '$number $streetName';
  }

  /// Generate random zip code (4 digits)
  static String generateZipCode() {
    return (1000 + _random.nextInt(8999)).toString();
  }

  /// Generate complete randomized demo data
  static Map<String, dynamic> generateCompleteData() {
    final firstName = generateFirstName();
    final middleName = generateMiddleName();
    final lastName = generateLastName();
    final region = generateRegion();
    final province = generateProvince(region);
    final city = generateCity(province);

    return {
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'username': generateUsername(firstName, lastName),
      'dateOfBirth': generateDateOfBirth(),
      'sex': generateSex(),
      'nationalIdNumber': generateNationalIdNumber(),
      'region': region,
      'province': province,
      'city': city,
      'barangay': generateBarangay(),
      'street': generateStreet(),
      'zipCode': generateZipCode(),
    };
  }
}
