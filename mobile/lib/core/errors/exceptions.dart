// Exceptions techniques levées par les data sources.
// Converties en Failure dans les repositories.

class NetworkException implements Exception {
  const NetworkException();
}

class ServerException implements Exception {
  /// Code d'erreur backend (`otp_cooldown`, `username_taken`, etc.).
  final String code;
  final String message;
  final int? statusCode;

  const ServerException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ServerException($code, $message)';
}
