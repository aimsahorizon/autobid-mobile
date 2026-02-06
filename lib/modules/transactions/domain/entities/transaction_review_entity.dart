import 'package:equatable/equatable.dart';

class TransactionReviewEntity extends Equatable {
  final String id;
  final String transactionId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const TransactionReviewEntity({
    required this.id,
    required this.transactionId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        transactionId,
        reviewerId,
        revieweeId,
        rating,
        comment,
        createdAt,
      ];
}
