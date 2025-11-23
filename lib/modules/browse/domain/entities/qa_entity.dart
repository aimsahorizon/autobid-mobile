/// Represents a Q&A question in auction detail
/// Users can ask questions, sellers respond, others can like
class QAEntity {
  /// Unique identifier for the question
  final String id;

  /// ID of the auction this question belongs to
  final String auctionId;

  /// Category of the question (General, Mechanical, History, etc.)
  final String category;

  /// The question text
  final String question;

  /// Name of the person who asked
  final String askedBy;

  /// When the question was asked
  final DateTime askedAt;

  /// Seller's response (null if not answered yet)
  final String? answer;

  /// When the seller responded (null if not answered)
  final DateTime? answeredAt;

  /// Number of likes on this question
  final int likesCount;

  /// Whether current user has liked this question
  final bool isLikedByUser;

  const QAEntity({
    required this.id,
    required this.auctionId,
    required this.category,
    required this.question,
    required this.askedBy,
    required this.askedAt,
    this.answer,
    this.answeredAt,
    this.likesCount = 0,
    this.isLikedByUser = false,
  });

  /// Check if question has been answered
  bool get isAnswered => answer != null;

  /// Response status text for UI display
  String get statusText => isAnswered ? 'Answered' : 'Pending';
}

/// Predefined categories for Q&A filtering
class QACategory {
  static const String all = 'All';
  static const String general = 'General';
  static const String mechanical = 'Mechanical';
  static const String history = 'History';
  static const String pricing = 'Pricing';
  static const String shipping = 'Shipping';

  /// Get all available categories for UI
  static List<String> get categories => [
        all,
        general,
        mechanical,
        history,
        pricing,
        shipping,
      ];
}

/// Common suggested questions users can quickly select
class SuggestedQuestions {
  static List<Map<String, String>> get questions => [
        {
          'category': QACategory.mechanical,
          'question': 'Has the car been in any accidents?'
        },
        {
          'category': QACategory.history,
          'question': 'How many previous owners?'
        },
        {
          'category': QACategory.mechanical,
          'question': 'When was the last oil change?'
        },
        {
          'category': QACategory.general,
          'question': 'Are there any known issues?'
        },
        {
          'category': QACategory.shipping,
          'question': 'Do you offer delivery options?'
        },
        {
          'category': QACategory.pricing,
          'question': 'Is the reserve price negotiable?'
        },
      ];
}
