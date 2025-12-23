import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class CreateSupportTicketUsecase {
  final SupportRepository repository;

  CreateSupportTicketUsecase(this.repository);

  Future<SupportTicketEntity> call({
    required String categoryId,
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    return await repository.createTicket(
      categoryId: categoryId,
      subject: subject,
      description: description,
      priority: priority,
    );
  }
}
