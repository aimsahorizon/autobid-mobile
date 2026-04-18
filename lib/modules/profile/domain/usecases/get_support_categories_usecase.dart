import 'package:autobid_mobile/modules/profile/domain/entities/support_ticket_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/support_repository.dart';

class GetSupportCategoriesUsecase {
  final SupportRepository repository;

  GetSupportCategoriesUsecase(this.repository);

  Future<List<SupportCategoryEntity>> call() async {
    return await repository.getCategories();
  }
}
