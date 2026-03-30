import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/profile_supabase_datasource.dart';
import '../../domain/entities/user_review_entity.dart';

/// Controller for managing user reviews state in the profile section.
class ReviewController extends ChangeNotifier {
  final ProfileSupabaseDataSource _dataSource;
  RealtimeChannel? _channel;
  String? _subscribedUserId;

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

  /// Load all reviews received by the given user and subscribe to realtime updates.
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

    _subscribeToReviews(userId);
  }

  /// Subscribe to realtime inserts/updates/deletes on transaction_reviews for this user.
  void _subscribeToReviews(String userId) {
    if (_subscribedUserId == userId) return;
    _unsubscribe();
    _subscribedUserId = userId;

    _channel = Supabase.instance.client
        .channel('reviews_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transaction_reviews',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'reviewee_id',
            value: userId,
          ),
          callback: (payload) {
            _refreshReviews(userId);
          },
        )
        .subscribe();
  }

  void _unsubscribe() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
      _subscribedUserId = null;
    }
  }

  /// Silently refresh reviews without showing loading state.
  Future<void> _refreshReviews(String userId) async {
    try {
      _reviews = await _dataSource.getReviewsForUser(userId);
      _summary = ReviewSummary.fromReviews(_reviews);
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[ReviewController] Refresh error: $e');
    }
  }

  /// Get the most recent N reviews for summary display.
  List<UserReviewEntity> getRecentReviews({int count = 3}) {
    if (_reviews.length <= count) return _reviews;
    return _reviews.sublist(0, count);
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }
}
