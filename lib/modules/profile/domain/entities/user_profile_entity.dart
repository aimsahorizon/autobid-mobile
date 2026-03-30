/// Represents user profile in the domain layer
class UserProfileEntity {
  final String id;
  final String coverPhotoUrl;
  final String profilePhotoUrl;
  final String fullName;
  final String username;
  final String email;
  final String? province;
  final String? city;
  final String? barangay;

  // Bidding & transaction stats (nullable — loaded on demand)
  final int? totalBids;
  final int? totalWins;
  final double? biddingRate;
  final int? totalTransactions;
  final int? completedTransactions;
  final int? selfCancelledTransactions;
  final double? successRate;
  final double? cancellationRate;

  const UserProfileEntity({
    required this.id,
    required this.coverPhotoUrl,
    required this.profilePhotoUrl,
    required this.fullName,
    required this.username,
    required this.email,
    this.province,
    this.city,
    this.barangay,
    this.totalBids,
    this.totalWins,
    this.biddingRate,
    this.totalTransactions,
    this.completedTransactions,
    this.selfCancelledTransactions,
    this.successRate,
    this.cancellationRate,
  });
}
