package sn.twelvepions.ws

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.TextWebSocketHandler
import sn.twelvepions.game.GameException
import sn.twelvepions.game.GameService
import sn.twelvepions.game.MatchResult
import sn.twelvepions.game.MatchmakingService
import sn.twelvepions.game.ai.dto.MoveDto
import sn.twelvepions.game.ai.dto.PositionDto
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.util.UUID

/**
 * Handler principal du WebSocket. Reçoit les messages JSON, dispatche, broadcast.
 *
 * Messages entrants :
 *   { "type": "queue.join" }
 *   { "type": "queue.leave" }
 *   { "type": "game.move",   "gameId": "...", "sequence": [...] }
 *   { "type": "game.resign", "gameId": "..." }
 *   { "type": "ping" }
 *
 * Messages sortants :
 *   { "type": "connected", "userId": "..." }
 *   { "type": "queue.queued" }
 *   { "type": "game.matched",  "state": <GameStateDto>, "yourColor": "X" | "O" }
 *   { "type": "game.update",   "state": <GameStateDto>, "lastMove": [...] }
 *   { "type": "game.ended",    "state": <GameStateDto> }
 *   { "type": "error", "code": "...", "message": "..." }
 *   { "type": "pong" }
 */
@Component
class GameWebSocketHandler(
    private val matchmaking: MatchmakingService,
    private val gameService: GameService,
    private val registry: SessionRegistry,
    private val mapper: ObjectMapper,
) : TextWebSocketHandler() {

    private val log = LoggerFactory.getLogger(GameWebSocketHandler::class.java)

    override fun afterConnectionEstablished(session: WebSocketSession) {
        val userId = userIdOf(session) ?: return
        registry.register(userId, session)
        log.info("WS connected: user={} ({} online)", userId, registry.onlineCount)
        sendJson(session, mapOf("type" to "connected", "userId" to userId.toString()))
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        val userId = userIdOf(session) ?: return
        registry.unregister(userId, session)
        // Sortir de la queue si on y était.
        runCatching { matchmaking.leaveQueue(userId) }
        log.info("WS closed: user={} status={} ({} online)", userId, status, registry.onlineCount)
    }

    override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
        val userId = userIdOf(session) ?: return
        try {
            val msg = mapper.readTree(message.payload)
            when (val type = msg["type"]?.asString()) {
                "queue.join" -> handleQueueJoin(userId, session)
                "queue.leave" -> handleQueueLeave(userId, session)
                "game.move" -> handleMove(userId, msg)
                "game.resign" -> handleResign(userId, msg)
                "ping" -> sendJson(session, mapOf("type" to "pong"))
                else -> sendError(session, "unknown_type", "Type inconnu : $type")
            }
        } catch (e: GameException) {
            sendError(session, "game_error", e.message ?: "Erreur de jeu")
        } catch (e: Exception) {
            log.error("WS handler error", e)
            sendError(session, "internal_error", e.message ?: "Erreur serveur")
        }
    }

    // ─── Handlers ────────────────────────────────────────────────────────────

    private fun handleQueueJoin(userId: UUID, session: WebSocketSession) {
        when (val r = matchmaking.joinQueue(userId)) {
            is MatchResult.Queued ->
                sendJson(session, mapOf("type" to "queue.queued"))
            is MatchResult.Matched -> {
                // Notifie chaque joueur avec sa propre couleur.
                val state = r.state
                val msgX = mapOf(
                    "type" to "game.matched",
                    "yourColor" to "X",
                    "state" to state,
                )
                val msgO = mapOf(
                    "type" to "game.matched",
                    "yourColor" to "O",
                    "state" to state,
                )
                registry.send(r.playerXId, mapper.writeValueAsString(msgX))
                registry.send(r.playerOId, mapper.writeValueAsString(msgO))
            }
        }
    }

    private fun handleQueueLeave(userId: UUID, session: WebSocketSession) {
        matchmaking.leaveQueue(userId)
        sendJson(session, mapOf("type" to "queue.left"))
    }

    private fun handleMove(userId: UUID, msg: JsonNode) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val sequence = parseSequence(msg["sequence"])
        val state = gameService.applyMove(gameId, userId, sequence)

        // Broadcast à X et O.
        val (xId, oId) = gameService.playersOf(gameId)
        val update = mapOf(
            "type" to if (state.status == "FINISHED") "game.ended" else "game.update",
            "lastMove" to sequence,
            "state" to state,
        )
        val payload = mapper.writeValueAsString(update)
        registry.broadcast(listOf(xId, oId), payload)
    }

    private fun handleResign(userId: UUID, msg: JsonNode) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val state = gameService.resign(gameId, userId)
        val (xId, oId) = gameService.playersOf(gameId)
        val payload = mapper.writeValueAsString(mapOf("type" to "game.ended", "state" to state))
        registry.broadcast(listOf(xId, oId), payload)
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private fun userIdOf(session: WebSocketSession): UUID? =
        session.attributes["userId"] as? UUID

    private fun sendJson(session: WebSocketSession, body: Any) {
        if (!session.isOpen) return
        synchronized(session) { session.sendMessage(TextMessage(mapper.writeValueAsString(body))) }
    }

    private fun sendError(session: WebSocketSession, code: String, message: String) {
        sendJson(session, mapOf("type" to "error", "code" to code, "message" to message))
    }

    private fun parseSequence(node: JsonNode?): List<MoveDto> {
        require(node != null && node.isArray) { "sequence must be an array" }
        val out = mutableListOf<MoveDto>()
        for (m in node) {
            val captured = m["captured"]
            out += MoveDto(
                from = PositionDto(m["from"]["r"].asInt(), m["from"]["c"].asInt()),
                to = PositionDto(m["to"]["r"].asInt(), m["to"]["c"].asInt()),
                captured = if (captured == null || captured.isNull) null
                    else PositionDto(captured["r"].asInt(), captured["c"].asInt()),
            )
        }
        return out
    }
}
