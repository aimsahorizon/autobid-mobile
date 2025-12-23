import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class GetTicketByIdUsecase {
  final SupportRepository repository;

  GetTicketByIdUsecase(this.repository);

  Future<SupportTicketEntity> call(String ticketId) async {
    return await repository.getTicketById(ticketId);
  }
}
