package sn.twelvepions.game

/**
 * Règles pures du 12 Pions sénégalais. Aucune fonction ne mute son entrée.
 * Toutes les opérations qui « modifient » un [Board] retournent un nouveau Board.
 *
 * Spec canonique : voir `shared/rules-spec.md`.
 */
object Rules {

    private val ORTHO = listOf(
        intArrayOf(1, 0),
        intArrayOf(-1, 0),
        intArrayOf(0, 1),
        intArrayOf(0, -1),
    )

    /** Direction d'avance du pion. X (haut) avance vers +r, O (bas) vers -r. */
    fun forwardDir(color: Color): Int = if (color == Color.X) 1 else -1

    /** 3 directions autorisées pour un pion (avant + 2 côtés). */
    private fun pionDirs(color: Color): List<IntArray> = listOf(
        intArrayOf(forwardDir(color), 0),
        intArrayOf(0, -1),
        intArrayOf(0, 1),
    )

    // ─── Coups simples (sans capture) ────────────────────────────────────────

    fun simpleMoves(board: Board, r: Int, c: Int): List<Move> {
        val piece = board.at(r, c) ?: return emptyList()
        val out = mutableListOf<Move>()
        if (piece.dame) {
            for ((dr, dc) in ORTHO) {
                var nr = r + dr; var nc = c + dc
                while (board.isInBounds(nr, nc) && board.at(nr, nc) == null) {
                    out += Move(Position(r, c), Position(nr, nc))
                    nr += dr; nc += dc
                }
            }
        } else {
            for ((dr, dc) in pionDirs(piece.color)) {
                val nr = r + dr; val nc = c + dc
                if (board.isInBounds(nr, nc) && board.at(nr, nc) == null) {
                    out += Move(Position(r, c), Position(nr, nc))
                }
            }
        }
        return out
    }

    // ─── Captures (un seul saut, sans la chaîne) ──────────────────────────────

    fun captureMoves(board: Board, r: Int, c: Int): List<Move> {
        val piece = board.at(r, c) ?: return emptyList()
        val out = mutableListOf<Move>()
        if (piece.dame) {
            for ((dr, dc) in ORTHO) {
                // Glisse jusqu'au premier obstacle.
                var nr = r + dr; var nc = c + dc
                while (board.isInBounds(nr, nc) && board.at(nr, nc) == null) {
                    nr += dr; nc += dc
                }
                if (!board.isInBounds(nr, nc)) continue
                val target = board.at(nr, nc) ?: continue
                if (target.color == piece.color) continue
                // Au moins une case vide après l'ennemi → atterrissages possibles.
                var lr = nr + dr; var lc = nc + dc
                while (board.isInBounds(lr, lc) && board.at(lr, lc) == null) {
                    out += Move(Position(r, c), Position(lr, lc), Position(nr, nc))
                    lr += dr; lc += dc
                }
            }
        } else {
            for ((dr, dc) in pionDirs(piece.color)) {
                val mr = r + dr; val mc = c + dc
                val tr = r + 2 * dr; val tc = c + 2 * dc
                if (!board.isInBounds(tr, tc)) continue
                val mid = board.at(mr, mc) ?: continue
                if (mid.color == piece.color) continue
                if (board.at(tr, tc) != null) continue
                out += Move(Position(r, c), Position(tr, tc), Position(mr, mc))
            }
        }
        return out
    }

    // ─── Application d'un coup ───────────────────────────────────────────────

    /**
     * Applique [move] sur [board] et retourne le nouveau plateau.
     * Gère la promotion automatique si le pion atteint la rangée adverse.
     */
    fun applyMove(board: Board, move: Move): Board {
        val piece = board.at(move.from.r, move.from.c)
            ?: error("No piece at ${move.from}")
        val becomesDame = !piece.dame && shouldPromote(piece.color, move.to.r)
        val newPiece = if (becomesDame) piece.copy(dame = true) else piece
        var b = board.set(move.from.r, move.from.c, null)
        if (move.captured != null) {
            b = b.set(move.captured.r, move.captured.c, null)
        }
        b = b.set(move.to.r, move.to.c, newPiece)
        return b
    }

    private fun shouldPromote(color: Color, r: Int): Boolean =
        (color == Color.X && r == BOARD_SIZE - 1) || (color == Color.O && r == 0)

    // ─── Promotion solo (« lonely pion ») ────────────────────────────────────

    /**
     * Si une couleur n'a plus qu'**un seul pion non-dame**, ce pion est
     * automatiquement promu. À appeler en fin de tour.
     */
    fun autoPromoteLast(board: Board): Board {
        var b = board
        for (color in Color.entries) {
            val positions = mutableListOf<Position>()
            for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
                val p = b.at(r, c) ?: continue
                if (p.color == color) positions += Position(r, c)
            }
            if (positions.size == 1) {
                val pos = positions[0]
                val p = b.at(pos.r, pos.c)!!
                if (!p.dame) b = b.set(pos.r, pos.c, p.copy(dame = true))
            }
        }
        return b
    }

    // ─── Disponibilités ──────────────────────────────────────────────────────

    fun hasAnyCapture(board: Board, color: Color): Boolean {
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            if (p.color != color) continue
            if (captureMoves(board, r, c).isNotEmpty()) return true
        }
        return false
    }

    fun hasAnyMove(board: Board, color: Color): Boolean {
        if (hasAnyCapture(board, color)) return true
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            if (p.color != color) continue
            if (simpleMoves(board, r, c).isNotEmpty()) return true
        }
        return false
    }

    // ─── Énumération de tours complets ────────────────────────────────────────

    /**
     * Retourne tous les [Turn] légaux pour [color] depuis [board].
     * Si une capture est possible, **seuls** les tours capturants sont retournés
     * (captures forcées). Les chaînes de captures (Coudou) sont entièrement développées.
     */
    fun enumerateTurns(board: Board, color: Color): List<Turn> {
        val captureTurns = mutableListOf<Turn>()
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            if (p.color != color) continue
            for (m in captureMoves(board, r, c)) {
                val nb = applyMove(board, m)
                val rest = continueChain(nb, m.to.r, m.to.c)
                if (rest.isEmpty()) {
                    captureTurns += Turn(listOf(m))
                } else {
                    for (sub in rest) captureTurns += Turn(listOf(m) + sub.sequence)
                }
            }
        }
        if (captureTurns.isNotEmpty()) return captureTurns

        // Pas de capture : coups simples.
        val simples = mutableListOf<Turn>()
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = board.at(r, c) ?: continue
            if (p.color != color) continue
            for (m in simpleMoves(board, r, c)) simples += Turn(listOf(m))
        }
        return simples
    }

    private fun continueChain(board: Board, r: Int, c: Int): List<Turn> {
        val cs = captureMoves(board, r, c)
        if (cs.isEmpty()) return emptyList()
        val out = mutableListOf<Turn>()
        for (m in cs) {
            val nb = applyMove(board, m)
            val rest = continueChain(nb, m.to.r, m.to.c)
            if (rest.isEmpty()) out += Turn(listOf(m))
            else for (sub in rest) out += Turn(listOf(m) + sub.sequence)
        }
        return out
    }
}
