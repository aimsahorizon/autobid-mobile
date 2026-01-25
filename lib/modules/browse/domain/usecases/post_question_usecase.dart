import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/qa_entity.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for posting a new question to an auction
class PostQuestionUseCase {
  final AuctionDetailRepository repository;

  PostQuestionUseCase(this.repository);

  Future<Either<Failure, QAEntity>> call({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  }) {
    return repository.postQuestion(
      auctionId: auctionId,
      userId: userId,
      category: category,
      question: question,
    );
  }
}
