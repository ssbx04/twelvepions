package sn.twelvepions.ws

import jakarta.annotation.PreDestroy
import org.springframework.stereotype.Component
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

@Component
class ChallengeRegistry {

    data class Challenge(val challengerId: UUID, val targetId: UUID)

    private val executor = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "challenge-timer").apply { isDaemon = true }
    }
    private val pending = ConcurrentHashMap<UUID, Challenge>()
    private val tasks  = ConcurrentHashMap<UUID, ScheduledFuture<*>>()

    fun create(challengeId: UUID, challengerId: UUID, targetId: UUID, onExpire: (UUID) -> Unit) {
        pending[challengeId] = Challenge(challengerId, targetId)
        val future = executor.schedule({
            if (pending.remove(challengeId) != null) {
                tasks.remove(challengeId)
                onExpire(challengeId)
            }
        }, CHALLENGE_TIMEOUT_S, TimeUnit.SECONDS)
        tasks[challengeId] = future
    }

    /** Consomme le défi (accepté ou refusé). Retourne null si déjà expiré/consommé. */
    fun consume(challengeId: UUID): Challenge? {
        val c = pending.remove(challengeId) ?: return null
        tasks.remove(challengeId)?.cancel(false)
        return c
    }

    /** Annule tous les défis envoyés par ce joueur (déconnexion). */
    fun cancelByChallenger(challengerId: UUID): List<Pair<UUID, UUID>> =
        pending.filter { it.value.challengerId == challengerId }.map { (id, c) ->
            consume(id)
            id to c.targetId
        }

    /** Annule tous les défis reçus par ce joueur (déconnexion). */
    fun cancelByTarget(targetId: UUID): List<Pair<UUID, UUID>> =
        pending.filter { it.value.targetId == targetId }.map { (id, c) ->
            consume(id)
            id to c.challengerId
        }

    @PreDestroy fun shutdown() = executor.shutdownNow()

    companion object {
        const val CHALLENGE_TIMEOUT_S: Long = 30L
    }
}
