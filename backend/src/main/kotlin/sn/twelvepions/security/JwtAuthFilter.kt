package sn.twelvepions.security

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken
import org.springframework.security.core.context.SecurityContextHolder
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter
import java.util.UUID

/**
 * Lit le header `Authorization: Bearer <jwt>`, valide le token, et installe
 * un Authentication dans le SecurityContext avec l'UUID du user comme principal.
 */
@Component
class JwtAuthFilter(
    private val jwtService: JwtService,
) : OncePerRequestFilter() {

    override fun doFilterInternal(
        request: HttpServletRequest,
        response: HttpServletResponse,
        chain: FilterChain,
    ) {
        val header = request.getHeader("Authorization")
        if (header != null && header.startsWith("Bearer ")) {
            val token = header.substring(7)
            try {
                val claims = jwtService.parse(token)
                val userId = UUID.fromString(claims.subject)
                val auth = UsernamePasswordAuthenticationToken(userId, null, emptyList())
                SecurityContextHolder.getContext().authentication = auth
            } catch (_: Exception) {
                // Token invalide / expiré : on laisse passer sans auth, le endpoint
                // protégé renverra 401 via l'AuthenticationEntryPoint.
            }
        }
        chain.doFilter(request, response)
    }
}
