package sn.twelvepions.auth.dto

import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Pattern
import jakarta.validation.constraints.Size
import sn.twelvepions.auth.UserLevel

private const val PHONE_REGEX = "^\\+221\\d{9}$"
private const val USERNAME_REGEX = "^[a-z0-9_]{3,20}$"

data class PhoneRequest(
    @field:Pattern(regexp = PHONE_REGEX, message = "Format attendu : +221XXXXXXXXX (9 chiffres)")
    val phone: String,
)

data class VerifyOtpRequest(
    @field:Pattern(regexp = PHONE_REGEX)
    val phone: String,
    @field:Pattern(regexp = "^\\d{6}$", message = "Code OTP : 6 chiffres")
    val code: String,
)

data class CompleteProfileRequest(
    @field:NotBlank
    @field:Size(min = 2, max = 100, message = "Nom complet : 2 à 100 caractères")
    val fullName: String,
    @field:Pattern(regexp = USERNAME_REGEX, message = "Username : 3-20 caractères, [a-z0-9_]")
    val username: String,
    val level: UserLevel,
)

data class AuthResponse(
    val token: String,
    val profileComplete: Boolean,
    val user: UserDto,
)

data class UserDto(
    val id: String,
    val phone: String,
    val fullName: String?,
    val username: String?,
    val level: UserLevel?,
    val elo: Int,
)

data class UsernameAvailableResponse(val available: Boolean)
