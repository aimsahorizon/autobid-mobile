import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../browse/data/datasources/invites_supabase_datasource.dart';

class GetAuctionInvitesUseCase {
  final InvitesSupabaseDatasource datasource;
  GetAuctionInvitesUseCase(this.datasource);

  Future<Either<Failure, List<Map<String, dynamic>>>> call(String auctionId) async {
    try {
      final results = await datasource.getAuctionInvites(auctionId);
      return Right(results);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class InviteUserUseCase {
  final InvitesSupabaseDatasource datasource;
  InviteUserUseCase(this.datasource);

  Future<Either<Failure, String>> call({
    required String auctionId,
    required String identifier,
    required String type,
  }) async {
    try {
      final inviteId = await datasource.inviteUser(
        auctionId: auctionId,
        identifier: identifier,
        type: type,
      );
      return Right(inviteId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

class DeleteInviteUseCase {
  final InvitesSupabaseDatasource datasource;
  DeleteInviteUseCase(this.datasource);

  Future<Either<Failure, void>> call(String inviteId) async {
    try {
      await datasource.deleteInvite(inviteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
