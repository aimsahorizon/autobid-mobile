import 'package:autobid_mobile/modules/profile/domain/entities/support_ticket_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/support_repository.dart';

class GetUserTicketsUsecase {
  final SupportRepository repository;

  GetUserTicketsUsecase(this.repository);

  Future<List<SupportTicketEntity>> call({
    TicketStatus? status,
    int? limit,
    int? offset,
  }) async {
    return await repository.getUserTickets(
      status: status,
      limit: limit,
      offset: offset,
    );
  }
}
