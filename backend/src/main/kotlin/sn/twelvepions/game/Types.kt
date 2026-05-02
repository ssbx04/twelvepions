package sn.twelvepions.game

/** Taille du plateau (5×5). */
const val BOARD_SIZE = 5

/** Couleur d'un joueur. X = Vert (en haut, commence), O = Rouge (en bas). */
enum class Color {
    X, O;

    fun opponent(): Color = if (this == X) O else X
}

/** Une pièce sur le plateau : pion (par défaut) ou dame. */
data class Piece(val color: Color, val dame: Boolean = false)

/** Coordonnées d'une case. r = ligne (0 en haut), c = colonne (0 à gauche). */
data class Position(val r: Int, val c: Int)

/**
 * Un coup unique : déplacement de [from] vers [to], avec capture optionnelle.
 * Une chaîne de captures est représentée par un [Turn] composé de plusieurs Move.
 */
data class Move(
    val from: Position,
    val to: Position,
    val captured: Position? = null,
)

/** Un tour complet : 1 ou plusieurs Move (chaîne de captures). */
data class Turn(val sequence: List<Move>) {
    init {
        require(sequence.isNotEmpty()) { "Turn must have at least one Move" }
    }
}

/** Raison d'une victoire. */
enum class WinReason { CAPTURE_ALL, BLOCKED }

/** Résultat de fin de partie. */
sealed class Outcome {
    data class Win(val winner: Color, val reason: WinReason) : Outcome()
    data object Draw : Outcome()
}
