package sn.twelvepions.game.ai

import sn.twelvepions.game.Board
import sn.twelvepions.game.Color
import sn.twelvepions.game.Rules
import sn.twelvepions.game.Turn

/** Résultat d'une recherche : meilleur tour trouvé, son score, profondeur atteinte. */
data class BestMoveResult(val turn: Turn?, val score: Int, val depth: Int)

/**
 * Moteur de l'IA Mariama : alpha-beta avec table de transposition,
 * iterative deepening optionnel, et budget temps.
 *
 * @see Evaluator pour la fonction d'évaluation.
 */
object Mariama {

    private const val INF = 1_000_000
    private const val WIN_SCORE = 100_000

    /** Exception interne pour interrompre la recherche au timeout. */
    private class TimeoutException : RuntimeException() {
        override fun fillInStackTrace(): Throwable = this
    }

    fun findBestMove(board: Board, color: Color, options: FindBestMoveOptions): BestMoveResult {
        val tt = TranspositionTable()
        val budget = options.timeBudgetMs
        val deadline = budget?.let { System.currentTimeMillis() + it }

        // Pas d'iterative deepening : recherche directe à maxDepth.
        if (deadline == null) {
            val ctx = SearchCtx(tt, deadline = null)
            val (turn, score) = searchRoot(board, color, options.maxDepth, ctx)
            return BestMoveResult(turn, score, options.maxDepth)
        }

        // Iterative deepening : on remonte progressivement jusqu'à la limite ou timeout.
        var bestTurn: Turn? = null
        var bestScore = 0
        var bestDepth = 0
        var depth = options.startDepth.coerceAtLeast(1)

        while (depth <= options.maxDepth) {
            val ctx = SearchCtx(tt, deadline)
            try {
                val (turn, score) = searchRoot(board, color, depth, ctx)
                if (turn != null) {
                    bestTurn = turn
                    bestScore = score
                    bestDepth = depth
                }
            } catch (_: TimeoutException) {
                break
            }
            depth++
            if (System.currentTimeMillis() >= deadline) break
        }
        return BestMoveResult(bestTurn, bestScore, bestDepth)
    }

    private class SearchCtx(val tt: TranspositionTable, val deadline: Long?) {
        fun checkTime() {
            if (deadline != null && System.currentTimeMillis() >= deadline) {
                throw TimeoutException()
            }
        }
    }

    private fun searchRoot(
        board: Board,
        color: Color,
        depth: Int,
        ctx: SearchCtx,
    ): Pair<Turn?, Int> {
        val turns = Rules.enumerateTurns(board, color)
        if (turns.isEmpty()) return null to -WIN_SCORE

        var alpha = -INF
        val beta = INF
        var bestScore = -INF
        var bestTurn: Turn? = null

        // Re-ordonne les coups en mettant le précédent meilleur en premier (TT).
        val ttKey = TranspositionTable.hash(board, color)
        val ttEntry = ctx.tt.get(ttKey)
        val orderedIdx = orderIndices(turns.size, ttEntry?.bestIdx)

        var bestIdx = 0
        for (i in orderedIdx) {
            val turn = turns[i]
            val nb = applyTurn(board, turn)
            val score = -alphaBeta(nb, color.opponent(), depth - 1, -beta, -alpha, ctx)
            if (score > bestScore) {
                bestScore = score
                bestTurn = turn
                bestIdx = i
            }
            if (score > alpha) alpha = score
            if (alpha >= beta) break
        }

        ctx.tt.put(ttKey, TtEntry(depth, bestScore, TtFlag.EXACT, bestIdx))
        return bestTurn to bestScore
    }

    private fun alphaBeta(
        board: Board,
        color: Color,
        depth: Int,
        alphaIn: Int,
        beta: Int,
        ctx: SearchCtx,
    ): Int {
        ctx.checkTime()

        // Probe TT
        val ttKey = TranspositionTable.hash(board, color)
        val ttEntry = ctx.tt.get(ttKey)
        if (ttEntry != null && ttEntry.depth >= depth) {
            when (ttEntry.flag) {
                TtFlag.EXACT -> return ttEntry.score
                TtFlag.LOWER -> if (ttEntry.score >= beta) return ttEntry.score
                TtFlag.UPPER -> if (ttEntry.score <= alphaIn) return ttEntry.score
            }
        }

        if (depth <= 0) {
            return Evaluator.evaluate(board, color)
        }

        val turns = Rules.enumerateTurns(board, color)
        if (turns.isEmpty()) {
            // Pas de coups → on perd ce tour. Score très négatif (atténué par profondeur
            // pour préférer les défaites lointaines aux défaites immédiates).
            return -WIN_SCORE + (100 - depth)
        }

        var alpha = alphaIn
        var bestScore = -INF
        var bestIdx = 0
        val orderedIdx = orderIndices(turns.size, ttEntry?.bestIdx)

        for (i in orderedIdx) {
            val turn = turns[i]
            val nb = applyTurn(board, turn)
            val score = -alphaBeta(nb, color.opponent(), depth - 1, -beta, -alpha, ctx)
            if (score > bestScore) {
                bestScore = score
                bestIdx = i
            }
            if (score > alpha) alpha = score
            if (alpha >= beta) break
        }

        val flag = when {
            bestScore <= alphaIn -> TtFlag.UPPER
            bestScore >= beta -> TtFlag.LOWER
            else -> TtFlag.EXACT
        }
        ctx.tt.put(ttKey, TtEntry(depth, bestScore, flag, bestIdx))
        return bestScore
    }

    /** Applique tous les coups d'un Turn (chaîne de captures) sur le plateau. */
    private fun applyTurn(board: Board, turn: Turn): Board {
        var b = board
        for (m in turn.sequence) b = Rules.applyMove(b, m)
        // Promotion solo (lonely pion) à la fin du tour.
        return Rules.autoPromoteLast(b)
    }

    /** Renvoie une liste d'indices de 0..n-1 avec [preferred] en tête s'il est valide. */
    private fun orderIndices(n: Int, preferred: Int?): IntArray {
        if (preferred == null || preferred < 0 || preferred >= n) {
            return IntArray(n) { it }
        }
        val out = IntArray(n)
        out[0] = preferred
        var idx = 1
        for (i in 0 until n) {
            if (i == preferred) continue
            out[idx++] = i
        }
        return out
    }
}
