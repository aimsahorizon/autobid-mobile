import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

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
