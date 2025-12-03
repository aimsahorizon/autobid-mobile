import '../../domain/entities/qa_entity.dart';

/// Mock data source for Q&A questions
/// Provides sample Q&A data for development and testing
class QAMockDataSource {
  /// Simulates fetching Q&A from backend
  /// Returns list of questions sorted by date (newest first)
  Future<List<QAEntity>> getQuestions(String auctionId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return [
      QAEntity(
        id: 'qa_001',
        auctionId: auctionId,
        category: QACategory.condition,
        question: 'What is the current mileage of the vehicle?',
        askedBy: 'John D.',
        askedAt: now.subtract(const Duration(days: 1)),
        answer:
            'The current mileage is 45,000 kilometers. Regular maintenance records are available.',
        answeredAt: now.subtract(const Duration(hours: 20)),
        likesCount: 12,
        isLikedByUser: true,
      ),
      QAEntity(
        id: 'qa_002',
        auctionId: auctionId,
        category: QACategory.history,
        question: 'Has the car been in any accidents?',
        askedBy: 'Maria S.',
        askedAt: now.subtract(const Duration(days: 2)),
        answer: 'No, the car has a clean title with no accident history.',
        answeredAt: now.subtract(const Duration(days: 1, hours: 5)),
        likesCount: 8,
      ),
      QAEntity(
        id: 'qa_003',
        auctionId: auctionId,
        category: QACategory.general,
        question: 'Are all the original keys included?',
        askedBy: 'Mike R.',
        askedAt: now.subtract(const Duration(hours: 6)),
        likesCount: 3,
        // Not answered yet
      ),
      QAEntity(
        id: 'qa_004',
        auctionId: auctionId,
        category: QACategory.features,
        question: 'Does it have a spare tire and jack?',
        askedBy: 'Ana L.',
        askedAt: now.subtract(const Duration(days: 3)),
        answer:
            'Yes, it comes with a full-size spare tire, jack, and all necessary tools.',
        answeredAt: now.subtract(const Duration(days: 2)),
        likesCount: 5,
      ),
      QAEntity(
        id: 'qa_005',
        auctionId: auctionId,
        category: QACategory.price,
        question: 'What is the reserve price?',
        askedBy: 'Carlos M.',
        askedAt: now.subtract(const Duration(hours: 12)),
        answer:
            'The reserve price is confidential, but it\'s set at a fair market value.',
        answeredAt: now.subtract(const Duration(hours: 10)),
        likesCount: 15,
      ),
      QAEntity(
        id: 'qa_006',
        auctionId: auctionId,
        category: QACategory.documents,
        question: 'Are all registration papers up to date?',
        askedBy: 'David K.',
        askedAt: now.subtract(const Duration(hours: 3)),
        likesCount: 2,
        // Pending answer
      ),
    ];
  }

  /// Simulates posting a new question
  Future<bool> postQuestion(
    String auctionId,
    String category,
    String question,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock success
    return true;
  }

  /// Simulates toggling like on a question
  Future<bool> toggleLike(String questionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }
}
