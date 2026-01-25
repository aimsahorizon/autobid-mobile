import 'package:equatable/equatable.dart';

/// Base Failure class for the application.
/// All Failures should extend this class.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Represents a failure from a remote server/API.
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

/// Represents a failure from a local cache/database.
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}

/// Represents an authentication failure.
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication Failure']);
}

/// Represents a general unknown failure.
class GeneralFailure extends Failure {
  const GeneralFailure([super.message = 'Something went wrong']);
}

/// Represents a network connectivity failure.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network Failure']);
}

/// Represents a resource not found failure.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource Not Found']);
}

/// Represents a storage or file system failure.
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Storage Failure']);
}

/// Represents a permission/authorization failure.
class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission Denied']);
}
