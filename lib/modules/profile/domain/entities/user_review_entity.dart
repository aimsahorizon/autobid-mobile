import 'package:equatable/equatable.dart';

/// A review received by a user, enriched with reviewer info for display.
class UserReviewEntity extends Equatable {
  final String id;
  final String transactionId;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const UserReviewEntity({
    required this.id,
    required this.transactionId,
    required this.reviewerId,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    transactionId,
    reviewerId,
    reviewerName,
    reviewerPhotoUrl,
    rating,
    comment,
    createdAt,
  ];
}

/// Summary stats for a user's reviews.
class ReviewSummary extends Equatable {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // {5: 10, 4: 5, 3: 2, 2: 1, 1: 0}

  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewSummary.fromReviews(List<UserReviewEntity> reviews) {
    if (reviews.isEmpty) {
      return const ReviewSummary(
        averageRating: 0,
        totalReviews: 0,
        ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      );
    }

    final total = reviews.length;
    final sum = reviews.fold<int>(0, (acc, r) => acc + r.rating);
    final avg = sum / total;

    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }

    return ReviewSummary(
      averageRating: avg,
      totalReviews: total,
      ratingDistribution: distribution,
    );
  }

  @override
  List<Object?> get props => [averageRating, totalReviews, ratingDistribution];
}
