/// Mock data source for guest auctions
/// Provides demo auction data for testing without database
class GuestMockDataSource {
  /// Simulated network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Get mock auction listings for guest mode
  Future<List<Map<String, dynamic>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  }) async {
    await _simulateDelay();

    final mockAuctions = [
      {
        'id': 'mock-1',
        'title': '2020 Toyota Camry LE',
        'description': 'Well-maintained sedan with low mileage. Perfect condition.',
        'category': 'Sedan',
        'image_url': 'https://images.unsplash.com/photo-1605559424843-9e4c228bf1c2?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': 'mock-2',
        'title': '2019 Honda Civic Sport',
        'description': 'Sporty and fuel-efficient. Single owner, garage kept.',
        'category': 'Sedan',
        'image_url': 'https://images.unsplash.com/photo-1617531653332-bd46c24f2068?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 5)).toIso8601String(),
      },
      {
        'id': 'mock-3',
        'title': '2021 Ford Mustang GT',
        'description': 'Powerful V8 engine. Excellent performance vehicle.',
        'category': 'Sports Car',
        'image_url': 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'mock-4',
        'title': '2018 Mazda CX-5 Touring',
        'description': 'Compact SUV with great features. Very reliable.',
        'category': 'SUV',
        'image_url': 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
      },
      {
        'id': 'mock-5',
        'title': '2022 Tesla Model 3 Long Range',
        'description': 'Electric sedan with autopilot. Low mileage, like new.',
        'category': 'Electric',
        'image_url': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 12)).toIso8601String(),
      },
      {
        'id': 'mock-6',
        'title': '2017 Nissan Altima SV',
        'description': 'Comfortable midsize sedan. Great value for money.',
        'category': 'Sedan',
        'image_url': 'https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
      },
      {
        'id': 'mock-7',
        'title': '2020 BMW X5 xDrive40i',
        'description': 'Luxury SUV with premium features. Immaculate condition.',
        'category': 'Luxury SUV',
        'image_url': 'https://images.unsplash.com/photo-1619405399517-d7fce0f13302?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 'mock-8',
        'title': '2019 Mercedes-Benz C-Class',
        'description': 'Premium sedan with leather interior. Exceptional ride.',
        'category': 'Luxury Sedan',
        'image_url': 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?w=800',
        'status': 'active',
        'start_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'end_date': DateTime.now().add(const Duration(hours: 6)).toIso8601String(),
      },
    ];

    // Apply offset and limit
    final start = offset.clamp(0, mockAuctions.length);
    final end = (offset + limit).clamp(0, mockAuctions.length);

    return mockAuctions.sublist(start, end);
  }
}
