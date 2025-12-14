/// Represents an individual seller answer attached to a Q&A entry.
class QAAnswerEntity {
  final String id;
  final String sellerId;
  final String answer;
  final DateTime createdAt;

  const QAAnswerEntity({
    required this.id,
    required this.sellerId,
    required this.answer,
    required this.createdAt,
  });
}

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

  /// All seller responses, sorted by creation time ascending
  final List<QAAnswerEntity> answers;

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
    this.answers = const [],
    this.likesCount = 0,
    this.isLikedByUser = false,
  });

  /// Latest reply if available
  QAAnswerEntity? get latestAnswer => answers.isNotEmpty ? answers.last : null;

  /// Convenience getter for the most recent answer text
  String? get answer => latestAnswer?.answer;

  /// Convenience getter for when the latest answer was created
  DateTime? get answeredAt => latestAnswer?.createdAt;

  /// Check if question has been answered
  bool get isAnswered => latestAnswer != null;

  /// Response status text for UI display
  String get statusText => isAnswered ? 'Answered' : 'Pending';
}

/// Predefined categories for Q&A filtering
/// IMPORTANT: These must match the database CHECK constraint in sql/11_qa_schema.sql
class QACategory {
  static const String all = 'all';
  static const String general = 'general';
  static const String condition = 'condition';
  static const String history = 'history';
  static const String features = 'features';
  static const String documents = 'documents';
  static const String price = 'price';

  /// Get all available categories for UI
  static List<String> get categories => [
    all,
    general,
    condition,
    history,
    features,
    documents,
    price,
  ];

  /// Format category for display (capitalize first letter)
  static String formatForDisplay(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }
}

/// Common suggested questions users can quickly select
class SuggestedQuestions {
  static List<Map<String, String>> get questions => [
    {
      'category': QACategory.condition,
      'question': 'What is the current mileage?',
    },
    {
      'category': QACategory.history,
      'question': 'Has the car been in any accidents?',
    },
    {
      'category': QACategory.condition,
      'question': 'When was the last service performed?',
    },
    {
      'category': QACategory.features,
      'question': 'Does it have a spare tire and tools?',
    },
    {
      'category': QACategory.documents,
      'question': 'Are all registration papers available?',
    },
    {
      'category': QACategory.price,
      'question': 'Is the reserve price negotiable?',
    },
  ];
}
