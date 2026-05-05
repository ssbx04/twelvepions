package sn.twelvepions.ws

import jakarta.annotation.PreDestroy
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import sn.twelvepions.game.GameService
import tools.jackson.databind.ObjectMapper
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Garde-fou de reconnexion : quand un joueur disparaît du WS pendant qu'une partie
 * est active, on lui laisse [GRACE_MILLIS] pour revenir avant de le déclarer forfait.
 *
 * État runtime uniquement (perdu si redémarrage backend).
 */
@Component
class ReconnectGuard(
    private val gameService: GameService,
    private val registry: SessionRegistry,
    private val turnTimer: TurnTimer,
    private val mapper: ObjectMapper,
) {
    private val log = LoggerFactory.getLogger(ReconnectGuard::class.java)
    private val executor = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "reconnect-guard").apply { isDaemon = true }
    }
    private val tasks = ConcurrentHashMap<UUID, ScheduledFuture<*>>()

    /** Programme un forfait dans [GRACE_MILLIS] si [userId] ne se reconnecte pas.
     *  Suspend le turn timer pendant la fenêtre de grâce. */
    fun armDisconnect(userId: UUID, gameId: UUID): Long {
        cancelDisconnect(userId, gameId)
        turnTimer.pause(gameId)
        val deadline = System.currentTimeMillis() + GRACE_MILLIS
        val future = executor.schedule({ fire(userId, gameId) }, GRACE_MILLIS, TimeUnit.MILLISECONDS)
        tasks[userId] = future
        return deadline
    }

    /** Annule le forfait pour [userId] et reprend le turn timer de [gameId] si fourni. */
    fun cancelDisconnect(userId: UUID, gameId: UUID? = null): Long? {
        tasks.remove(userId)?.cancel(false)
        return gameId?.let { turnTimer.resume(it) }
    }

    private fun fire(userId: UUID, gameId: UUID) {
        try {
            tasks.remove(userId)
            // Si le joueur s'est reconnecté entre-temps, on ne forfeit pas.
            if (registry.get(userId) != null) return
            val state = gameService.resign(gameId, userId)
            turnTimer.cancel(gameId)
            val (xId, oId) = gameService.playersOf(gameId)
            val payload = mapper.writeValueAsString(
                mapOf("type" to "game.ended", "state" to state),
            )
            registry.broadcast(listOf(xId, oId), payload)
        } catch (e: Exception) {
            log.error("Disconnect forfeit failed for user={} game={}", userId, gameId, e)
        }
    }

    @PreDestroy
    fun shutdown() {
        executor.shutdownNow()
    }

    companion object {
        const val GRACE_MILLIS: Long = 30_000L
    }
}
