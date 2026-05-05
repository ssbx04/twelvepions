import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session.dart';
import '../entities/user.dart';
import '../entities/user_level.dart';

/// Contrat du module d'authentification.
abstract class AuthRepository {
  /// Demande l'envoi d'un code OTP par SMS au numéro indiqué.
  Future<Either<Failure, String>> sendOtp(String phone);

  /// Vérifie le code OTP. En cas de succès :
  /// - Persiste le JWT en secure storage.
  /// - Retourne la session courante.
  Future<Either<Failure, AuthSession>> verifyOtp(String phone, String code);

  /// Complète le profil après le 1er signup. Renvoie une session rafraîchie.
  Future<Either<Failure, AuthSession>> completeProfile({
    required String fullName,
    required String username,
    required UserLevel level,
  });

  /// Vérifie si un username est disponible.
  Future<Either<Failure, bool>> checkUsername(String username);

  /// Récupère le profil de l'utilisateur courant.
  Future<Either<Failure, User>> getMe();

  /// Supprime le JWT du secure storage et déconnecte l'utilisateur.
  Future<void> logout();

  /// True si un JWT existe en secure storage.
  Future<bool> hasSession();
}
