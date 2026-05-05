package sn.twelvepions.auth

import org.slf4j.LoggerFactory
import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service
import java.security.SecureRandom
import java.time.Duration

/**
 * Génère, stocke et valide les OTP via Redis.
 *
 * Clés Redis :
 * - `otp:code:{phone}`     hash {code, attempts}, TTL 5 min
 * - `otp:cooldown:{phone}` valeur "1", TTL 30 s
 * - `otp:hourly:{phone}`   compteur INCR, TTL 1 h
 *
 * En dev, le code est imprimé dans le terminal du backend (config `app.otp.provider=console`).
 * En prod, on branchera Africa's Talking ici.
 */
@Service
class OtpService(
    private val redis: StringRedisTemplate,
) {
    private val log = LoggerFactory.getLogger(OtpService::class.java)
    private val rng = SecureRandom()

    private val codeTtl = Duration.ofMinutes(5)
    private val cooldownTtl = Duration.ofSeconds(30)
    private val hourlyTtl = Duration.ofHours(1)
    private val maxAttempts = 3
    private val maxPerHour = 5

    fun sendOtp(phone: String): String {
        val cooldownKey = cooldownKey(phone)
        if (redis.hasKey(cooldownKey)) throw OtpCooldownException()

        val hourlyKey = hourlyKey(phone)
        val count = redis.opsForValue().increment(hourlyKey) ?: 1L
        if (count == 1L) redis.expire(hourlyKey, hourlyTtl)
        if (count > maxPerHour) throw OtpRateLimitException()

        val code = String.format("%06d", rng.nextInt(1_000_000))
        val codeKey = codeKey(phone)
        val hashOps = redis.opsForHash<String, String>()
        hashOps.put(codeKey, "code", code)
        hashOps.put(codeKey, "attempts", "0")
        redis.expire(codeKey, codeTtl)
        redis.opsForValue().set(cooldownKey, "1", cooldownTtl)

        log.info("┌──────────────────────────────────────────┐")
        log.info("│  📱  OTP pour {}  →  {}      │", phone, code)
        log.info("│      valide 5 min, 3 essais max          │")
        log.info("└──────────────────────────────────────────┘")

        return code
    }

    fun verifyOtp(phone: String, code: String) {
        val codeKey = codeKey(phone)
        val hashOps = redis.opsForHash<String, String>()
        val storedCode = hashOps.get(codeKey, "code") ?: throw OtpExpiredException()
        val attempts = hashOps.get(codeKey, "attempts")?.toIntOrNull() ?: 0

        if (attempts >= maxAttempts) {
            redis.delete(codeKey)
            throw OtpAttemptsExceededException()
        }

        if (storedCode != code) {
            hashOps.increment(codeKey, "attempts", 1)
            throw OtpInvalidCodeException()
        }

        // Code valide : on supprime l'OTP, le cooldown et le compteur horaire.
        redis.delete(codeKey)
        redis.delete(cooldownKey(phone))
    }

    private fun codeKey(phone: String) = "otp:code:$phone"
    private fun cooldownKey(phone: String) = "otp:cooldown:$phone"
    private fun hourlyKey(phone: String) = "otp:hourly:$phone"
}
