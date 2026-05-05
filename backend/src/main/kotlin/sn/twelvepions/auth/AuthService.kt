package sn.twelvepions.auth

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import sn.twelvepions.auth.dto.AuthResponse
import sn.twelvepions.auth.dto.CompleteProfileRequest
import sn.twelvepions.auth.dto.UserDto
import sn.twelvepions.security.JwtService
import java.util.UUID

@Service
class AuthService(
    private val users: UserRepository,
    private val otp: OtpService,
    private val jwt: JwtService,
) {
    fun sendOtp(phone: String): String {
        return otp.sendOtp(phone)
    }

    @Transactional
    fun verifyOtp(phone: String, code: String): AuthResponse {
        otp.verifyOtp(phone, code)
        val user = users.findByPhone(phone) ?: users.save(User(phone = phone))
        return buildAuthResponse(user)
    }

    @Transactional
    fun completeProfile(userId: UUID, req: CompleteProfileRequest): AuthResponse {
        val user = users.findById(userId).orElseThrow { UserNotFoundException() }
        if (user.profileComplete) throw ProfileAlreadyCompleteException()
        if (users.existsByUsernameIgnoreCase(req.username)) throw UsernameTakenException()

        user.fullName = req.fullName.trim()
        user.username = req.username
        user.level = req.level
        user.elo = req.level.seedElo
        users.save(user)

        return buildAuthResponse(user)
    }

    fun getUser(userId: UUID): UserDto {
        val user = users.findById(userId).orElseThrow { UserNotFoundException() }
        return user.toDto()
    }

    fun isUsernameAvailable(username: String): Boolean =
        !users.existsByUsernameIgnoreCase(username)

    private fun buildAuthResponse(user: User): AuthResponse {
        val token = jwt.generate(user.id, user.profileComplete)
        return AuthResponse(token = token, profileComplete = user.profileComplete, user = user.toDto())
    }

    private fun User.toDto() = UserDto(
        id = id.toString(),
        phone = phone,
        fullName = fullName,
        username = username,
        level = level,
        elo = elo,
    )
}
