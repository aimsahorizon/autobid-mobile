import '../../domain/entities/user_profile_entity.dart';

/// Data model for user profile that handles JSON serialization
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.coverPhotoUrl,
    required super.profilePhotoUrl,
    required super.fullName,
    required super.username,
    required super.email,
    super.province,
    super.city,
    super.barangay,
    super.totalBids,
    super.totalWins,
    super.biddingRate,
    super.totalTransactions,
    super.completedTransactions,
    super.selfCancelledTransactions,
    super.successRate,
    super.cancellationRate,
  });

  /// Create model from JSON (Supabase response from users table)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Build full name from first, middle, last name fields
    final firstName = json['first_name'] as String? ?? '';
    final middleName = json['middle_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';

    // Combine names with proper spacing
    final fullName = middleName.isNotEmpty
        ? '$firstName $middleName $lastName'
        : '$firstName $lastName';

    // Extract address data
    // user_addresses is a One-to-Many relation, so it returns a List
    final addressesList = json['user_addresses'] as List<dynamic>?;
    Map<String, dynamic>? addressData;

    if (addressesList != null && addressesList.isNotEmpty) {
      // Try to find default address, otherwise use first
      addressData =
          addressesList.firstWhere(
                (addr) => addr['is_default'] == true,
                orElse: () => addressesList.first,
              )
              as Map<String, dynamic>;
    }

    return UserProfileModel(
      id: json['id'] as String,
      coverPhotoUrl: json['cover_photo_url'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      fullName: fullName.trim(),
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      province: addressData?['province'] as String?,
      city: addressData?['city'] as String?,
      // Map barangay from address_line2 or dedicated field if available later
      // Current schema: address_line1, address_line2, city, province, postal_code
      barangay: addressData?['address_line2'] as String?,
    );
  }

  /// Create model from get_user_bidding_stats RPC response
  factory UserProfileModel.fromStatsJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['user_id'] as String? ?? '',
      coverPhotoUrl: '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      fullName: (json['full_name'] as String? ?? '').trim(),
      username: json['username'] as String? ?? '',
      email: '',
      province: json['province'] as String?,
      city: json['city'] as String?,
      totalBids: json['total_bids'] as int? ?? 0,
      totalWins: json['total_wins'] as int? ?? 0,
      biddingRate: (json['bidding_rate'] as num?)?.toDouble() ?? 0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      completedTransactions: json['completed_transactions'] as int? ?? 0,
      selfCancelledTransactions:
          json['self_cancelled_transactions'] as int? ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0,
      cancellationRate: (json['cancellation_rate'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cover_photo_url': coverPhotoUrl,
      'profile_photo_url': profilePhotoUrl,
      'full_name': fullName,
      'username': username,
      'email': email,
      'user_addresses': [
        {'province': province, 'city': city, 'address_line2': barangay},
      ],
    };
  }
}
