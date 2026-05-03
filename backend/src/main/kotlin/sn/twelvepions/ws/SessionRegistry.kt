package sn.twelvepions.ws

import org.springframework.stereotype.Component
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Map d'utilisateurs connectés en WebSocket. Une seule session par user :
 * une nouvelle connexion ferme l'ancienne.
 */
@Component
class SessionRegistry {

    private val byUser = ConcurrentHashMap<UUID, WebSocketSession>()

    fun register(userId: UUID, session: WebSocketSession) {
        val previous = byUser.put(userId, session)
        if (previous != null && previous != session && previous.isOpen) {
            try { previous.close() } catch (_: Exception) { /* ignore */ }
        }
    }

    fun unregister(userId: UUID, session: WebSocketSession) {
        byUser.remove(userId, session)
    }

    fun get(userId: UUID): WebSocketSession? = byUser[userId]

    fun send(userId: UUID, payload: String) {
        val s = byUser[userId] ?: return
        if (!s.isOpen) return
        synchronized(s) { s.sendMessage(TextMessage(payload)) }
    }

    fun broadcast(userIds: Collection<UUID>, payload: String) {
        userIds.forEach { send(it, payload) }
    }

    val onlineCount: Int get() = byUser.size
}
