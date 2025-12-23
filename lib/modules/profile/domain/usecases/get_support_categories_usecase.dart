import '../entities/support_ticket_entity.dart';
import '../repositories/support_repository.dart';

class GetSupportCategoriesUsecase {
  final SupportRepository repository;

  GetSupportCategoriesUsecase(this.repository);

  Future<List<SupportCategoryEntity>> call() async {
    return await repository.getCategories();
  }
}
