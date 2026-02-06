import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/review_controller.dart';
import '../widgets/reviews_section.dart';

/// Full-page view of all reviews received by the current user.
class UserReviewsPage extends StatefulWidget {
  final ReviewController reviewController;

  const UserReviewsPage({super.key, required this.reviewController});

  @override
  State<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> {
  int _selectedFilter = 0; // 0 = All, 1-5 = star filter

  List<dynamic> get _filteredReviews {
    if (_selectedFilter == 0) return widget.reviewController.reviews;
    return widget.reviewController.reviews
        .where((r) => r.rating == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings'), centerTitle: true),
      body: ListenableBuilder(
        listenable: widget.reviewController,
        builder: (context, _) {
          if (widget.reviewController.isLoading &&
              !widget.reviewController.hasReviews) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!widget.reviewController.hasReviews) {
            return _buildEmptyState(theme, isDark);
          }

          return CustomScrollView(
            slivers: [
              // Rating summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RatingSummaryBar(
                    summary: widget.reviewController.summary,
                  ),
                ),
              ),

              // Filter chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildFilterChips(theme, isDark),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Results count
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${_filteredReviews.length} ${_filteredReviews.length == 1 ? 'review' : 'reviews'}${_selectedFilter > 0 ? ' with $_selectedFilter ${_selectedFilter == 1 ? 'star' : 'stars'}' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Reviews list
              if (_filteredReviews.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildNoMatchState(theme, isDark),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ReviewCard(review: _filteredReviews[index]),
                      );
                    }, childCount: _filteredReviews.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    final labels = ['All', '5★', '4★', '3★', '2★', '1★'];
    final values = [0, 5, 4, 3, 2, 1];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(labels.length, (index) {
          final isSelected = _selectedFilter == values[index];
          final count = values[index] == 0
              ? widget.reviewController.summary.totalReviews
              : widget
                        .reviewController
                        .summary
                        .ratingDistribution[values[index]] ??
                    0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${labels[index]} ($count)'),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = values[index]);
              },
              selectedColor: ColorConstants.primary.withValues(alpha: 0.15),
              checkmarkColor: ColorConstants.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? ColorConstants.primary
                    : isDark
                    ? ColorConstants.textPrimaryDark
                    : ColorConstants.textPrimaryLight,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? ColorConstants.primary
                      : isDark
                      ? ColorConstants.borderDark
                      : ColorConstants.borderLight,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 72,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No Reviews Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete transactions to start receiving reviews from other users.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            Text(
              'No reviews with this rating',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 0),
              child: const Text('Show all reviews'),
            ),
          ],
        ),
      ),
    );
  }
}
