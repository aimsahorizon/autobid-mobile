import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for liking a question
class LikeQuestionUseCase {
  final AuctionDetailRepository repository;

  LikeQuestionUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String questionId,
    required String userId,
  }) {
    return repository.likeQuestion(questionId: questionId, userId: userId);
  }
}
