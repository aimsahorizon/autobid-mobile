import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

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
