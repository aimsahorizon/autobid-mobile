import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class UpdateTicketStatusUsecase {
  final SupportRepository repository;

  UpdateTicketStatusUsecase(this.repository);

  Future<SupportTicketEntity> call({
    required String ticketId,
    required TicketStatus status,
  }) async {
    return await repository.updateTicketStatus(
      ticketId: ticketId,
      status: status,
    );
  }
}
