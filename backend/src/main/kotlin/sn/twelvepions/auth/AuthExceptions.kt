package sn.twelvepions.auth

sealed class AuthException(message: String) : RuntimeException(message)

class OtpCooldownException : AuthException("Patientez 30 secondes avant de redemander un code")
class OtpRateLimitException : AuthException("Trop de demandes — réessayez dans une heure")
class OtpExpiredException : AuthException("Code expiré ou inexistant — redemandez un code")
class OtpInvalidCodeException : AuthException("Code incorrect")
class OtpAttemptsExceededException : AuthException("Trop d'essais incorrects — redemandez un nouveau code")

class UsernameTakenException : AuthException("Ce username est déjà pris")
class ProfileAlreadyCompleteException : AuthException("Profil déjà complété")
class UserNotFoundException : AuthException("Utilisateur introuvable")
