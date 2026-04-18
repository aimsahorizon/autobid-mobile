import 'package:autobid_mobile/modules/profile/domain/entities/support_ticket_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/support_repository.dart';

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
