import 'package:autobid_mobile/modules/profile/domain/entities/support_ticket_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/support_repository.dart';

class GetTicketByIdUsecase {
  final SupportRepository repository;

  GetTicketByIdUsecase(this.repository);

  Future<SupportTicketEntity> call(String ticketId) async {
    return await repository.getTicketById(ticketId);
  }
}
