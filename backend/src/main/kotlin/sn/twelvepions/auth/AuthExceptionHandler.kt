package sn.twelvepions.auth

import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice

@RestControllerAdvice
class AuthExceptionHandler {

    @ExceptionHandler(AuthException::class)
    fun handleAuth(ex: AuthException): ResponseEntity<ErrorResponse> {
        val status = when (ex) {
            is OtpCooldownException -> HttpStatus.TOO_MANY_REQUESTS
            is OtpRateLimitException -> HttpStatus.TOO_MANY_REQUESTS
            is OtpExpiredException -> HttpStatus.GONE
            is OtpInvalidCodeException -> HttpStatus.UNAUTHORIZED
            is OtpAttemptsExceededException -> HttpStatus.UNAUTHORIZED
            is UsernameTakenException -> HttpStatus.CONFLICT
            is ProfileAlreadyCompleteException -> HttpStatus.CONFLICT
            is UserNotFoundException -> HttpStatus.NOT_FOUND
        }
        return ResponseEntity.status(status).body(ErrorResponse(ex.code(), ex.message ?: ""))
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidation(ex: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val msg = ex.bindingResult.fieldErrors.joinToString("; ") {
            "${it.field}: ${it.defaultMessage}"
        }
        return ResponseEntity.badRequest().body(ErrorResponse("validation_error", msg))
    }

    private fun AuthException.code(): String = when (this) {
        is OtpCooldownException -> "otp_cooldown"
        is OtpRateLimitException -> "otp_rate_limit"
        is OtpExpiredException -> "otp_expired"
        is OtpInvalidCodeException -> "otp_invalid"
        is OtpAttemptsExceededException -> "otp_attempts_exceeded"
        is UsernameTakenException -> "username_taken"
        is ProfileAlreadyCompleteException -> "profile_already_complete"
        is UserNotFoundException -> "user_not_found"
    }
}

data class ErrorResponse(val error: String, val message: String)
