package sn.twelvepions.ws

import org.springframework.context.annotation.Configuration
import org.springframework.web.socket.config.annotation.EnableWebSocket
import org.springframework.web.socket.config.annotation.WebSocketConfigurer
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry

@Configuration
@EnableWebSocket
class WsConfig(
    private val handler: GameWebSocketHandler,
    private val handshakeInterceptor: JwtHandshakeInterceptor,
) : WebSocketConfigurer {

    override fun registerWebSocketHandlers(registry: WebSocketHandlerRegistry) {
        registry.addHandler(handler, "/ws")
            .addInterceptors(handshakeInterceptor)
            .setAllowedOriginPatterns("*")
    }
}
