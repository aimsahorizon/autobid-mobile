import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

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
