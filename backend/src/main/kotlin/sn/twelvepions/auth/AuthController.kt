package sn.twelvepions.auth

import jakarta.validation.Valid
import jakarta.validation.constraints.Pattern
import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.validation.annotation.Validated
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import sn.twelvepions.auth.dto.AuthResponse
import sn.twelvepions.auth.dto.CompleteProfileRequest
import sn.twelvepions.auth.dto.PhoneRequest
import sn.twelvepions.auth.dto.PhoneResponse
import sn.twelvepions.auth.dto.UsernameAvailableResponse
import sn.twelvepions.auth.dto.VerifyOtpRequest
import java.util.UUID

@RestController
@RequestMapping("/auth")
@Validated
class AuthController(
    private val authService: AuthService,
) {
    @PostMapping("/phone")
    fun sendOtp(@Valid @RequestBody req: PhoneRequest): PhoneResponse {
        val devOtp = authService.sendOtp(req.phone)
        return PhoneResponse(devOtp = devOtp)
    }

    @PostMapping("/verify-otp")
    fun verifyOtp(@Valid @RequestBody req: VerifyOtpRequest): AuthResponse =
        authService.verifyOtp(req.phone, req.code)

    @PostMapping("/complete-profile")
    fun completeProfile(
        @AuthenticationPrincipal userId: UUID,
        @Valid @RequestBody req: CompleteProfileRequest,
    ): AuthResponse = authService.completeProfile(userId, req)

    @GetMapping("/check-username")
    fun checkUsername(
        @RequestParam("u")
        @Pattern(regexp = "^[a-z0-9_]{3,20}$", message = "Username : 3-20 caractères, [a-z0-9_]")
        u: String,
    ): UsernameAvailableResponse =
        UsernameAvailableResponse(authService.isUsernameAvailable(u))
}
