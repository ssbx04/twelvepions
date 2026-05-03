package sn.twelvepions.game.ai

import sn.twelvepions.game.BOARD_SIZE
import sn.twelvepions.game.Board
import sn.twelvepions.game.Color

/** Type de score stocké dans la table de transposition. */
enum class TtFlag { EXACT, LOWER, UPPER }

/** Une entrée de la table de transposition. */
data class TtEntry(val depth: Int, val score: Int, val flag: TtFlag, val bestIdx: Int)

/**
 * Table de transposition simple basée sur un Map<String, TtEntry>.
 * La clé est un hash du plateau + couleur dont c'est le tour.
 *
 * 5×5 cases × 5 états (vide, X, x, O, o) ne tiennent pas dans un Long ;
 * on utilise une String compacte (26 caractères : 25 cases + couleur).
 */
class TranspositionTable {
    private val map = HashMap<String, TtEntry>(1 shl 14)

    fun get(key: String): TtEntry? = map[key]
    fun put(key: String, entry: TtEntry) { map[key] = entry }
    fun clear() = map.clear()
    val size: Int get() = map.size

    companion object {
        fun hash(board: Board, turn: Color): String {
            val sb = StringBuilder(BOARD_SIZE * BOARD_SIZE + 1)
            for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
                val p = board.at(r, c)
                sb.append(
                    when {
                        p == null -> '.'
                        p.color == Color.X && !p.dame -> 'X'
                        p.color == Color.X && p.dame -> 'x'
                        p.color == Color.O && !p.dame -> 'O'
                        else -> 'o'
                    },
                )
            }
            sb.append(if (turn == Color.X) 'X' else 'O')
            return sb.toString()
        }
    }
}
