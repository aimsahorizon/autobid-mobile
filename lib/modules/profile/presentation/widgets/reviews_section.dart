import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/review_controller.dart';
import '../../domain/entities/user_review_entity.dart';

/// A compact review card used in both the profile summary and the full reviews page.
class ReviewCard extends StatelessWidget {
  final UserReviewEntity review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reviewer avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.15),
                backgroundImage: review.reviewerPhotoUrl != null
                    ? NetworkImage(review.reviewerPhotoUrl!)
                    : null,
                child: review.reviewerPhotoUrl == null
                    ? Text(
                        review.reviewerName.isNotEmpty
                            ? review.reviewerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              // Reviewer name + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _formatDate(review.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Star rating
              _buildStarRating(review.rating),
            ],
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: isDark
                    ? ColorConstants.textPrimaryDark
                    : ColorConstants.textPrimaryLight,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

/// Rating summary bar (used in the full reviews page header).
class RatingSummaryBar extends StatelessWidget {
  final ReviewSummary summary;

  const RatingSummaryBar({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Big average number
          Column(
            children: [
              Text(
                summary.averageRating.toStringAsFixed(1),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(height: 4),
              _buildStarRow(summary.averageRating),
              const SizedBox(height: 4),
              Text(
                '${summary.totalReviews} ${summary.totalReviews == 1 ? 'review' : 'reviews'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Distribution bars
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final star = 5 - index;
                final count = summary.ratingDistribution[star] ?? 0;
                final percentage = summary.totalReviews > 0
                    ? count / summary.totalReviews
                    : 0.0;
                return _buildDistributionRow(
                  star,
                  count,
                  percentage,
                  theme,
                  isDark,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star_rounded, color: Colors.amber, size: 18);
        } else if (index < rating) {
          return const Icon(
            Icons.star_half_rounded,
            color: Colors.amber,
            size: 18,
          );
        } else {
          return const Icon(
            Icons.star_outline_rounded,
            color: Colors.amber,
            size: 18,
          );
        }
      }),
    );
  }

  Widget _buildDistributionRow(
    int star,
    int count,
    double percentage,
    ThemeData theme,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text(
              '$star',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: isDark
                    ? ColorConstants.surfaceVariantDark
                    : ColorConstants.surfaceVariantLight,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section on the profile page showing a summary of reviews received.
class ReviewsSummarySection extends StatelessWidget {
  final ReviewController reviewController;
  final VoidCallback onViewAll;

  const ReviewsSummarySection({
    super.key,
    required this.reviewController,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: reviewController,
      builder: (context, _) {
        // Don't show anything while loading initially
        if (reviewController.isLoading && !reviewController.hasReviews) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.surfaceDark
                  : ColorConstants.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight,
              ),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? ColorConstants.surfaceDark
                : ColorConstants.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? ColorConstants.borderDark
                  : ColorConstants.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reviews & Ratings',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (reviewController.hasReviews)
                          Text(
                            '${reviewController.summary.averageRating.toStringAsFixed(1)} avg · ${reviewController.summary.totalReviews} ${reviewController.summary.totalReviews == 1 ? 'review' : 'reviews'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (reviewController.hasReviews)
                    // Average rating badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _ratingColor(
                          reviewController.summary.averageRating,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: _ratingColor(
                              reviewController.summary.averageRating,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviewController.summary.averageRating
                                .toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _ratingColor(
                                reviewController.summary.averageRating,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (!reviewController.hasReviews) ...[
                // Empty state
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 40,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No reviews yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete transactions to receive reviews',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Show recent reviews (max 3)
                ...reviewController
                    .getRecentReviews(count: 3)
                    .map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ReviewCard(review: review),
                      ),
                    ),

                const SizedBox(height: 4),

                // "View All Reviews" button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewAll,
                    icon: const Icon(Icons.reviews_outlined, size: 18),
                    label: Text(
                      'View All ${reviewController.summary.totalReviews} Reviews',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorConstants.primary,
                      side: BorderSide(
                        color: ColorConstants.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 4.0) return ColorConstants.success;
    if (rating >= 3.0) return ColorConstants.warning;
    return ColorConstants.error;
  }
}
