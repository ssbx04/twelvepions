package sn.twelvepions.ws

import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.server.ServerHttpRequest
import org.springframework.http.server.ServerHttpResponse
import org.springframework.http.server.ServletServerHttpRequest
import org.springframework.stereotype.Component
import org.springframework.web.socket.WebSocketHandler
import org.springframework.web.socket.server.HandshakeInterceptor
import sn.twelvepions.security.JwtService
import java.util.UUID

/**
 * Valide le JWT passé en query parameter (`?token=...`) lors du handshake WebSocket.
 * Stocke l'UUID du user dans `attributes["userId"]` pour usage par le handler.
 */
@Component
class JwtHandshakeInterceptor(
    private val jwt: JwtService,
) : HandshakeInterceptor {

    private val log = LoggerFactory.getLogger(JwtHandshakeInterceptor::class.java)

    override fun beforeHandshake(
        request: ServerHttpRequest,
        response: ServerHttpResponse,
        wsHandler: WebSocketHandler,
        attributes: MutableMap<String, Any>,
    ): Boolean {
        if (request !is ServletServerHttpRequest) {
            response.setStatusCode(HttpStatus.BAD_REQUEST)
            return false
        }
        val token = request.servletRequest.getParameter("token")
        if (token.isNullOrBlank()) {
            log.debug("WS handshake refusé : pas de token")
            response.setStatusCode(HttpStatus.UNAUTHORIZED)
            return false
        }
        return try {
            val claims = jwt.parse(token)
            attributes["userId"] = UUID.fromString(claims.subject)
            true
        } catch (e: Exception) {
            log.debug("WS handshake refusé : token invalide ({})", e.message)
            response.setStatusCode(HttpStatus.UNAUTHORIZED)
            false
        }
    }

    override fun afterHandshake(
        request: ServerHttpRequest,
        response: ServerHttpResponse,
        wsHandler: WebSocketHandler,
        exception: Exception?,
    ) {
        // rien
    }
}
