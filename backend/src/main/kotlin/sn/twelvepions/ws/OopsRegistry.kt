package sn.twelvepions.ws

import org.springframework.stereotype.Component
import sn.twelvepions.game.Color
import sn.twelvepions.game.Position
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * État runtime des sanctions surplace en attente. Quand un joueur a joué un coup
 * fautif (coup simple ou chaîne incomplète alors qu'une capture était dispo),
 * l'adversaire a la possibilité de réclamer OOPS et de retirer un pion fautif
 * **avant de jouer son propre tour**.
 *
 * État runtime uniquement (perdu si redémarrage backend).
 */
@Component
class OopsRegistry {

    data class Pending(val claimerColor: Color, val faultyPositions: Set<Position>)

    private val pending = ConcurrentHashMap<UUID, Pending>()

    fun set(gameId: UUID, claimer: Color, positions: Set<Position>) {
        pending[gameId] = Pending(claimer, positions)
    }

    fun get(gameId: UUID): Pending? = pending[gameId]

    fun clear(gameId: UUID) {
        pending.remove(gameId)
    }
}
