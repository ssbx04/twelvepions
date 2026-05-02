package sn.twelvepions.game

/**
 * Plateau immutable de 5×5 cases. Chaque case contient une [Piece] ou null.
 * Toutes les opérations qui « modifient » le plateau retournent un nouveau [Board].
 */
data class Board(val cells: List<List<Piece?>>) {

    init {
        require(cells.size == BOARD_SIZE) { "Board must have $BOARD_SIZE rows" }
        require(cells.all { it.size == BOARD_SIZE }) { "Each row must have $BOARD_SIZE cells" }
    }

    /** Récupère la pièce à (r,c), ou null si vide / hors plateau. */
    fun at(r: Int, c: Int): Piece? = cells.getOrNull(r)?.getOrNull(c)

    /** True si (r,c) est une coordonnée valide. */
    fun isInBounds(r: Int, c: Int): Boolean =
        r in 0 until BOARD_SIZE && c in 0 until BOARD_SIZE

    /** Retourne un nouveau Board avec la case (r,c) remplacée par [piece]. */
    fun set(r: Int, c: Int, piece: Piece?): Board {
        val newRow = cells[r].toMutableList().also { it[c] = piece }
        val newCells = cells.toMutableList().also { it[r] = newRow }
        return Board(newCells)
    }

    /** Compte les pièces d'une couleur donnée. */
    fun count(color: Color): Int =
        cells.sumOf { row -> row.count { it?.color == color } }

    companion object {
        /**
         * Plateau initial :
         * - X (Vert) en haut : rangées 0,1 + (2,0)(2,1) → 12 pions
         * - O (Rouge) en bas : rangées 3,4 + (2,3)(2,4) → 12 pions
         * - Case centrale (2,2) vide
         */
        fun initial(): Board {
            val cells: List<List<Piece?>> = List(BOARD_SIZE) { r ->
                List(BOARD_SIZE) { c ->
                    when {
                        r == 0 || r == 1 -> Piece(Color.X)
                        r == 2 && (c == 0 || c == 1) -> Piece(Color.X)
                        r == 3 || r == 4 -> Piece(Color.O)
                        r == 2 && (c == 3 || c == 4) -> Piece(Color.O)
                        else -> null
                    }
                }
            }
            return Board(cells)
        }

        /**
         * Construit un plateau depuis une représentation textuelle (utile pour les tests).
         * Caractères : `.` = vide, `X` = pion vert, `x` = dame verte,
         * `O` = pion rouge, `o` = dame rouge.
         *
         * Exemple :
         * ```
         * Board.parse(listOf(
         *   "XXXXX",
         *   "XXXXX",
         *   "XX.OO",
         *   "OOOOO",
         *   "OOOOO",
         * ))
         * ```
         */
        fun parse(rows: List<String>): Board {
            require(rows.size == BOARD_SIZE) { "Expected $BOARD_SIZE rows, got ${rows.size}" }
            val cells = rows.mapIndexed { r, row ->
                require(row.length == BOARD_SIZE) { "Row $r has length ${row.length}, expected $BOARD_SIZE" }
                row.map { ch ->
                    when (ch) {
                        '.' -> null
                        'X' -> Piece(Color.X, dame = false)
                        'x' -> Piece(Color.X, dame = true)
                        'O' -> Piece(Color.O, dame = false)
                        'o' -> Piece(Color.O, dame = true)
                        else -> error("Invalid char '$ch' at row $r")
                    }
                }
            }
            return Board(cells)
        }
    }
}
