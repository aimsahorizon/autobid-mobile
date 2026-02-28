/// Thrown when a server/API call fails.
class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server Exception']);

  @override
  String toString() => message;
}

/// Thrown when a local cache operation fails.
class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache Exception']);

  @override
  String toString() => message;
}

/// Thrown when an authentication operation fails.
class AuthException implements Exception {
  final String message;
  const AuthException([this.message = 'Authentication Exception']);

  @override
  String toString() => message;
}
