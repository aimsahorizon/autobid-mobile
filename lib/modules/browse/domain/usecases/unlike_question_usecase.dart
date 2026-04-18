import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for unliking a question
class UnlikeQuestionUseCase {
  final AuctionDetailRepository repository;

  UnlikeQuestionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String questionId,
    required String userId,
  }) {
    return repository.unlikeQuestion(questionId: questionId, userId: userId);
  }
}
