import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_datasource.dart';

/// Implementation of NotificationRepository using datasource
class NotificationRepositoryImpl implements NotificationRepository {
  final INotificationDataSource dataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getNotifications(
        userId: userId,
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount({required String userId}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getUnreadCount(userId: userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to get unread count: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead({
    required String notificationId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.markAsRead(notificationId: notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to mark as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> markAllAsRead() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.markAllAsRead();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to mark all as read: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification({
    required String notificationId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.deleteNotification(notificationId: notificationId);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Failed to delete notification: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<NotificationEntity>>> getUnreadNotifications({
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getUnreadNotifications(userId: userId);
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get unread notifications: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> respondToInvite({
    required String inviteId,
    required String decision,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await dataSource.respondToInvite(inviteId: inviteId, decision: decision);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Failed to respond to invite: ${e.toString()}'),
      );
    }
  }
}
