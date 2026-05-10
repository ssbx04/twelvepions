package sn.twelvepions.ws

import jakarta.annotation.PreDestroy
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import sn.twelvepions.config.FcmService
import sn.twelvepions.game.GameService
import tools.jackson.databind.ObjectMapper
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Compteur 30s par tour. Sur expiration, déclare forfait du joueur dont c'est le tour
 * via [GameService.timeoutCurrentTurn] et broadcaste `game.ended` aux deux joueurs.
 *
 * État runtime uniquement : si le serveur redémarre, les timers sont perdus jusqu'au
 * prochain coup. Acceptable pour le MVP, à reprendre si on scale multi-instance.
 */
@Component
class TurnTimer(
    private val gameService: GameService,
    private val registry: SessionRegistry,
    private val fcm: FcmService,
    private val mapper: ObjectMapper,
) {
    private val log = LoggerFactory.getLogger(TurnTimer::class.java)
    private val executor = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "turn-timer").apply { isDaemon = true }
    }
    private val tasks = ConcurrentHashMap<UUID, ScheduledFuture<*>>()
    private val deadlines = ConcurrentHashMap<UUID, Long>()
    private val paused = ConcurrentHashMap<UUID, Long>()

    /** Programme un nouveau timeout (annule le précédent). Retourne l'epoch ms d'expiration. */
    fun arm(gameId: UUID): Long = scheduleIn(gameId, TURN_MILLIS)

    fun cancel(gameId: UUID) {
        tasks.remove(gameId)?.cancel(false)
        deadlines.remove(gameId)
        paused.remove(gameId)
    }

    fun deadlineFor(gameId: UUID): Long? = deadlines[gameId]

    /** Suspend le timer en mémorisant le temps restant. No-op si pas armé ou déjà en pause. */
    fun pause(gameId: UUID) {
        if (paused.containsKey(gameId)) return
        val deadline = deadlines[gameId] ?: return
        val remaining = (deadline - System.currentTimeMillis()).coerceAtLeast(1L)
        tasks.remove(gameId)?.cancel(false)
        deadlines.remove(gameId)
        paused[gameId] = remaining
    }

    /** Reprend le timer avec le temps restant mémorisé. Retourne la nouvelle deadline ou null. */
    fun resume(gameId: UUID): Long? {
        val remaining = paused.remove(gameId) ?: return null
        return scheduleIn(gameId, remaining)
    }

    private fun scheduleIn(gameId: UUID, millis: Long): Long {
        tasks.remove(gameId)?.cancel(false)
        val deadline = System.currentTimeMillis() + millis
        val future = executor.schedule({ fire(gameId) }, millis, TimeUnit.MILLISECONDS)
        tasks[gameId] = future
        deadlines[gameId] = deadline
        return deadline
    }

    private fun fire(gameId: UUID) {
        try {
            val state = gameService.timeoutCurrentTurn(gameId)
            tasks.remove(gameId)
            deadlines.remove(gameId)
            if (state.status != "FINISHED") return
            val (xId, oId) = gameService.playersOf(gameId)
            val payload = mapper.writeValueAsString(
                mapOf("type" to "game.ended", "state" to state),
            )
            registry.broadcast(listOf(xId, oId), payload)
            listOf(xId, oId).filter { registry.get(it) == null }.forEach { offlineId ->
                fcm.sendToUser(offlineId, "12 Pions", "Tu as perdu par forfait (temps écoulé).")
            }
        } catch (e: Exception) {
            log.error("Turn timeout failed for game={}", gameId, e)
        }
    }

    @PreDestroy
    fun shutdown() {
        executor.shutdownNow()
    }

    companion object {
        const val TURN_MILLIS: Long = 30_000L
    }
}
