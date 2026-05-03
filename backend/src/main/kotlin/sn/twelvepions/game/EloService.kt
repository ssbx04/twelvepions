package sn.twelvepions.game

import org.springframework.stereotype.Service
import sn.twelvepions.auth.User
import sn.twelvepions.auth.UserRepository
import java.util.UUID
import kotlin.math.pow
import kotlin.math.roundToInt

/**
 * Calcul ELO standard (formule classique).
 *
 * - K = 32 (sensibilité du gain/perte d'ELO)
 * - Espérance(A) = 1 / (1 + 10^((eloB - eloA) / 400))
 * - newElo(A) = elo(A) + K × (score(A) - espérance(A))
 *   avec score = 1 (win), 0 (loss), 0.5 (draw)
 */
@Service
class EloService(
    private val users: UserRepository,
) {
    private val k = 32

    /**
     * Met à jour les ELO des deux joueurs en base. [winner] = X, O ou null pour un nul.
     * Retourne (deltaX, deltaO).
     */
    fun applyResult(playerXId: UUID, playerOId: UUID, winner: String?): Pair<Int, Int> {
        val ux = users.findById(playerXId).orElseThrow { IllegalArgumentException("Player X not found") }
        val uo = users.findById(playerOId).orElseThrow { IllegalArgumentException("Player O not found") }
        val (newX, newO) = compute(ux.elo, uo.elo, winner)
        val deltaX = newX - ux.elo
        val deltaO = newO - uo.elo
        ux.elo = newX
        uo.elo = newO
        users.save(ux)
        users.save(uo)
        return deltaX to deltaO
    }

    fun compute(eloX: Int, eloO: Int, winner: String?): Pair<Int, Int> {
        val expectedX = 1.0 / (1.0 + 10.0.pow((eloO - eloX) / 400.0))
        val expectedO = 1.0 - expectedX
        val (scoreX, scoreO) = when (winner) {
            "X" -> 1.0 to 0.0
            "O" -> 0.0 to 1.0
            else -> 0.5 to 0.5
        }
        val newX = (eloX + k * (scoreX - expectedX)).roundToInt()
        val newO = (eloO + k * (scoreO - expectedO)).roundToInt()
        return newX to newO
    }
}
