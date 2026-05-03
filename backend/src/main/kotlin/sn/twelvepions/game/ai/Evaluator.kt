package sn.twelvepions.game.ai

import sn.twelvepions.game.BOARD_SIZE
import sn.twelvepions.game.Board
import sn.twelvepions.game.Color
import sn.twelvepions.game.Rules

/**
 * Évaluation du plateau du point de vue de [color].
 * Score positif = bon pour [color], négatif = bon pour l'adversaire.
 *
 * Composantes :
 * - matériel        (pion=100, dame=240)
 * - avancement      (pion vers la rangée de promo) ×4
 * - centre          (proximité de la case centrale) ×12
 * - mobilité        (nombre de coups légaux) ×3
 * - menace          (pion capturable au prochain tour) -35
 * - restriction     (mobilité de l'adversaire) -2
 * - formation       (pion défendu par un allié dame ou ami) ×6
 */
object Evaluator {

    private const val PAWN = 100
    private const val DAME = 240
    private const val ADVANCE_W = 4
    private const val CENTER_W = 12
    private const val MOBILITY_W = 3
    private const val OPP_MOBILITY_W = 2
    private const val THREAT = 35
    private const val FORMATION_W = 6

    fun evaluate(board: Board, color: Color): Int {
        var score = 0
        val opponent = color.opponent()

        // Matériel + avancement + centre + formation
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            val sign = if (p.color == color) 1 else -1
            score += sign * (if (p.dame) DAME else PAWN)

            // Avancement (uniquement pour les pions, pas les dames)
            if (!p.dame) {
                val advance = if (p.color == Color.X) r else (BOARD_SIZE - 1 - r)
                score += sign * advance * ADVANCE_W
            }

            // Centre : 0 = bord, 2 = centre. Distance Manhattan inversée.
            val centerDist = kotlin.math.abs(r - 2) + kotlin.math.abs(c - 2)
            val centerScore = (4 - centerDist).coerceAtLeast(0)
            score += sign * centerScore * CENTER_W

            // Formation : pion défendu par un voisin ami.
            if (!p.dame) {
                if (hasAdjacentFriendly(board, r, c, p.color)) {
                    score += sign * FORMATION_W
                }
            }
        }

        // Mobilité (compte des Turns possibles)
        val myMoves = countMoves(board, color)
        val oppMoves = countMoves(board, opponent)
        score += myMoves * MOBILITY_W
        score -= oppMoves * OPP_MOBILITY_W

        // Menace : si l'adversaire peut me capturer un pion au prochain tour, -35.
        if (Rules.hasAnyCapture(board, opponent)) {
            score -= THREAT
        }

        return score
    }

    private fun hasAdjacentFriendly(board: Board, r: Int, c: Int, color: Color): Boolean {
        for (dr in -1..1) for (dc in -1..1) {
            if (dr == 0 && dc == 0) continue
            val nr = r + dr; val nc = c + dc
            val p = board.at(nr, nc) ?: continue
            if (p.color == color) return true
        }
        return false
    }

    private fun countMoves(board: Board, color: Color): Int {
        var n = 0
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            if (p.color != color) continue
            n += Rules.simpleMoves(board, r, c).size
            n += Rules.captureMoves(board, r, c).size
        }
        return n
    }
}
