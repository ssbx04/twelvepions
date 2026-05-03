package sn.twelvepions.game

import org.springframework.data.redis.core.StringRedisTemplate
import org.springframework.stereotype.Service
import sn.twelvepions.game.dto.GameStateDto
import java.util.UUID
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

sealed class MatchResult {
    data object Queued : MatchResult()
    data class Matched(val state: GameStateDto, val playerXId: UUID, val playerOId: UUID) : MatchResult()
}

/**
 * Matchmaking FIFO simple basé sur Redis (clé `matchmaking:queue`).
 *
 * Synchronisation : un mutex JVM protège la fenêtre LPOP+create-game pour éviter
 * deux joueurs se faisant attribuer le même adversaire en concurrence. Suffit
 * pour un déploiement single-instance (notre cas MVP). En multi-instance,
 * remplacer par un script Lua atomique.
 *
 * À enrichir plus tard : tri par ELO, fenêtre temporelle élargissante, etc.
 */
@Service
class MatchmakingService(
    private val redis: StringRedisTemplate,
    private val gameService: GameService,
) {
    private val queueKey = "matchmaking:queue"
    private val lock = ReentrantLock()

    fun joinQueue(userId: UUID): MatchResult {
        return lock.withLock {
            // Si déjà dans la queue, no-op.
            val current = redis.opsForList().range(queueKey, 0, -1) ?: emptyList()
            if (current.contains(userId.toString())) {
                return@withLock MatchResult.Queued
            }
            // Regarde s'il y a un autre joueur dispo.
            val opponentStr = current.firstOrNull { it != userId.toString() }
            if (opponentStr != null) {
                redis.opsForList().remove(queueKey, 0, opponentStr)
                val opponentId = UUID.fromString(opponentStr)
                // Tirage au sort de la couleur.
                val (xId, oId) = if (Math.random() < 0.5) userId to opponentId else opponentId to userId
                val state = gameService.createGame(xId, oId)
                MatchResult.Matched(state, xId, oId)
            } else {
                redis.opsForList().rightPush(queueKey, userId.toString())
                MatchResult.Queued
            }
        }
    }

    fun leaveQueue(userId: UUID) {
        lock.withLock {
            redis.opsForList().remove(queueKey, 0, userId.toString())
        }
    }
}
