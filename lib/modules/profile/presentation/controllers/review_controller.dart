import 'package:flutter/material.dart';
import '../../data/datasources/profile_supabase_datasource.dart';
import '../../domain/entities/user_review_entity.dart';

/// Controller for managing user reviews state in the profile section.
class ReviewController extends ChangeNotifier {
  final ProfileSupabaseDataSource _dataSource;

  ReviewController({required ProfileSupabaseDataSource dataSource})
    : _dataSource = dataSource;

  List<UserReviewEntity> _reviews = [];
  ReviewSummary _summary = const ReviewSummary(
    averageRating: 0,
    totalReviews: 0,
    ratingDistribution: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
  );
  bool _isLoading = false;
  String? _errorMessage;

  List<UserReviewEntity> get reviews => _reviews;
  ReviewSummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasReviews => _reviews.isNotEmpty;

  /// Load all reviews received by the given user.
  Future<void> loadReviews(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reviews = await _dataSource.getReviewsForUser(userId);
      _summary = ReviewSummary.fromReviews(_reviews);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load reviews';
      debugPrint('[ReviewController] Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Get the most recent N reviews for summary display.
  List<UserReviewEntity> getRecentReviews({int count = 3}) {
    if (_reviews.length <= count) return _reviews;
    return _reviews.sublist(0, count);
  }
}
