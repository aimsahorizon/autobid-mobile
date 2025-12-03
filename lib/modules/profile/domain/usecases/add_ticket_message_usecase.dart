import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class AddTicketMessageUsecase {
  final SupportRepository repository;

  AddTicketMessageUsecase(this.repository);

  Future<SupportMessageEntity> call({
    required String ticketId,
    required String message,
    List<String>? attachmentPaths,
  }) async {
    return await repository.addMessage(
      ticketId: ticketId,
      message: message,
      attachmentPaths: attachmentPaths,
    );
  }
}
