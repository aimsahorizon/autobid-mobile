import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/qa_entity.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for getting Q&A questions for an auction
class GetQuestionsUseCase {
  final AuctionDetailRepository repository;

  GetQuestionsUseCase(this.repository);

  Future<Either<Failure, List<QAEntity>>> call({
    required String auctionId,
    String? currentUserId,
  }) {
    return repository.getQuestions(
      auctionId: auctionId,
      currentUserId: currentUserId,
    );
  }
}
