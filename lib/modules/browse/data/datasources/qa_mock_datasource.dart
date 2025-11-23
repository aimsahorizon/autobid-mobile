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
        category: QACategory.mechanical,
        question: 'Has the car been in any accidents?',
        askedBy: 'John D.',
        askedAt: now.subtract(const Duration(days: 1)),
        answer:
            'No, the car has a clean title with no accident history. Carfax report is available upon request.',
        answeredAt: now.subtract(const Duration(hours: 20)),
        likesCount: 12,
        isLikedByUser: true,
      ),
      QAEntity(
        id: 'qa_002',
        auctionId: auctionId,
        category: QACategory.history,
        question: 'How many previous owners has this vehicle had?',
        askedBy: 'Maria S.',
        askedAt: now.subtract(const Duration(days: 2)),
        answer: 'This is a 2-owner vehicle. First owner had it for 3 years.',
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
        category: QACategory.shipping,
        question: 'Do you offer shipping to Cebu?',
        askedBy: 'Ana L.',
        askedAt: now.subtract(const Duration(days: 3)),
        answer:
            'Yes, we can arrange shipping to Cebu. Estimated cost is ₱25,000-30,000 depending on the carrier.',
        answeredAt: now.subtract(const Duration(days: 2)),
        likesCount: 5,
      ),
      QAEntity(
        id: 'qa_005',
        auctionId: auctionId,
        category: QACategory.pricing,
        question: 'What is the reserve price?',
        askedBy: 'Carlos M.',
        askedAt: now.subtract(const Duration(hours: 12)),
        answer:
            'The reserve price is confidential, but I can tell you it\'s set at a fair market value.',
        answeredAt: now.subtract(const Duration(hours: 10)),
        likesCount: 15,
      ),
      QAEntity(
        id: 'qa_006',
        auctionId: auctionId,
        category: QACategory.mechanical,
        question: 'When was the timing belt last replaced?',
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
