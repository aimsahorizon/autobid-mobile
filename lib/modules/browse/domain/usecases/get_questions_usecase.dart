import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

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
