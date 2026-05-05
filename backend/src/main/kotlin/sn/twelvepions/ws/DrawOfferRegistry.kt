package sn.twelvepions.ws

import org.springframework.stereotype.Component
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Suivi des demandes de nulle en cours et des refus accumulés par demandeur.
 *
 * Règle : un même joueur qui se voit refuser sa demande [MAX_REFUSALS] fois dans
 * la même partie est déclaré forfait (cap anti-spam).
 */
@Component
class DrawOfferRegistry {

    private val pendingByGame = ConcurrentHashMap<UUID, UUID>()
    private val refusalsByOfferer = ConcurrentHashMap<Pair<UUID, UUID>, Int>()

    /** Enregistre une demande. Renvoie false s'il y a déjà une demande en cours pour cette partie. */
    fun offer(gameId: UUID, offererId: UUID): Boolean {
        return pendingByGame.putIfAbsent(gameId, offererId) == null
    }

    fun pendingOffererOf(gameId: UUID): UUID? = pendingByGame[gameId]

    /** Consomme un accord et renvoie l'offreur d'origine (ou null si pas de pending). */
    fun consumeAccept(gameId: UUID): UUID? = pendingByGame.remove(gameId)

    /**
     * Consomme un refus. Renvoie l'offreur d'origine + le nouveau total de refus.
     * Si [DeclineResult.refusals] >= [MAX_REFUSALS], l'appelant doit déclarer forfait l'offreur.
     */
    fun consumeDecline(gameId: UUID): DeclineResult? {
        val offerer = pendingByGame.remove(gameId) ?: return null
        val key = gameId to offerer
        val newCount = refusalsByOfferer.merge(key, 1) { a, b -> a + b } ?: 1
        return DeclineResult(offererId = offerer, refusals = newCount)
    }

    /** Annule l'éventuelle demande en cours (sans la compter comme refus). */
    fun cancelPending(gameId: UUID): UUID? = pendingByGame.remove(gameId)

    /** Nettoie tout pour une partie terminée. */
    fun clearForGame(gameId: UUID) {
        pendingByGame.remove(gameId)
        refusalsByOfferer.keys.removeIf { it.first == gameId }
    }

    data class DeclineResult(val offererId: UUID, val refusals: Int)

    companion object {
        const val MAX_REFUSALS = 3
    }
}
