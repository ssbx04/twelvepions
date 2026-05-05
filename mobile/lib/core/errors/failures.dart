import 'package:equatable/equatable.dart';

/// Erreurs métier remontées par les repositories vers la couche présentation.
///
/// Toutes les exceptions techniques sont converties en Failure dans les
/// repositories. La couche présentation ne voit que des Failure.
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Réseau / serveur ─────────────────────────────────────────────────────

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Pas de connexion internet']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur, réessayez']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expirée, reconnectez-vous']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// ─── OTP ──────────────────────────────────────────────────────────────────

class OtpCooldownFailure extends Failure {
  const OtpCooldownFailure(super.message);
}

class OtpRateLimitFailure extends Failure {
  const OtpRateLimitFailure(super.message);
}

class OtpExpiredFailure extends Failure {
  const OtpExpiredFailure(super.message);
}

class OtpInvalidFailure extends Failure {
  const OtpInvalidFailure(super.message);
}

class OtpAttemptsExceededFailure extends Failure {
  const OtpAttemptsExceededFailure(super.message);
}

// ─── Profil ───────────────────────────────────────────────────────────────

class UsernameTakenFailure extends Failure {
  const UsernameTakenFailure(super.message);
}

class ProfileAlreadyCompleteFailure extends Failure {
  const ProfileAlreadyCompleteFailure(super.message);
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure(super.message);
}
