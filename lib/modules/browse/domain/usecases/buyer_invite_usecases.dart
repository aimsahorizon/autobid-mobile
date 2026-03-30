import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/invites_supabase_datasource.dart';

/// Use case for buyers to list their pending auction invites
class ListMyInvitesUseCase {
  final InvitesSupabaseDatasource datasource;
  ListMyInvitesUseCase(this.datasource);

  Future<Either<Failure, List<Map<String, dynamic>>>> call() async {
    try {
      final results = await datasource.listMyInvites();
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

/// Use case for buyers to respond to an auction invite (accept/reject)
class RespondToInviteUseCase {
  final InvitesSupabaseDatasource datasource;
  RespondToInviteUseCase(this.datasource);

  Future<Either<Failure, void>> call({
    required String inviteId,
    required String decision,
  }) async {
    try {
      await datasource.respondInvite(inviteId: inviteId, decision: decision);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
