package sn.twelvepions.game.ai

import org.junit.jupiter.api.Test
import sn.twelvepions.game.Board
import sn.twelvepions.game.Color
import sn.twelvepions.game.Position
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class MariamaTest {

    // ─── Évaluation ───────────────────────────────────────────────────────────

    @Test
    fun `eval is symmetric — opposite scores from each color`() {
        val b = Board.initial()
        val sx = Evaluator.evaluate(b, Color.X)
        val so = Evaluator.evaluate(b, Color.O)
        // Le plateau initial est symétrique : eval(X) ≈ -eval(O), à la mobilité
        // près qui peut différer. On vérifie au moins que les signes s'opposent.
        // En pratique sur l'initial, les deux scores doivent être très proches.
        assertTrue(kotlin.math.abs(sx + so) <= 6, "eval not symmetric: X=$sx, O=$so")
    }

    @Test
    fun `eval rewards material advantage`() {
        // X a 3 pions, O n'en a qu'1.
        val b = Board.parse(
            listOf(
                "XXX..",
                ".....",
                ".....",
                ".....",
                "....O",
            )
        )
        val s = Evaluator.evaluate(b, Color.X)
        assertTrue(s > 0, "X material advantage should give positive score, got $s")
    }

    // ─── Recherche : Mariama prend une capture forcée ────────────────────────

    @Test
    fun `Mariama plays the only capture available`() {
        // X capture O en (3,2) → atterrit (4,2) (et promo dame).
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                "..O..",
                ".....",
            )
        )
        val r = Mariama.findBestMove(b, Color.X, FindBestMoveOptions(maxDepth = 2))
        assertNotNull(r.turn)
        val first = r.turn!!.sequence[0]
        assertEquals(Position(2, 2), first.from)
        assertEquals(Position(3, 2), first.captured)
    }

    // ─── Capture en chaîne (Coudou) ──────────────────────────────────────────

    @Test
    fun `Mariama plays full capture chain`() {
        val b = Board.parse(
            listOf(
                "..X..",
                "..O..",
                ".....",
                "..O..",
                ".....",
            )
        )
        val r = Mariama.findBestMove(b, Color.X, FindBestMoveOptions(maxDepth = 4))
        assertNotNull(r.turn)
        // Doit être une chaîne de 2 captures.
        assertEquals(2, r.turn!!.sequence.size, "expected 2-capture chain")
    }

    // ─── Iterative deepening avec budget temps ───────────────────────────────

    @Test
    fun `Expert respects time budget`() {
        val b = Board.initial()
        val opts = Difficulty.EXPERT.options
        val start = System.currentTimeMillis()
        val r = Mariama.findBestMove(b, Color.X, opts)
        val elapsed = System.currentTimeMillis() - start
        // Tolérance large : l'iterative deepening doit s'arrêter < budget + 500ms
        assertTrue(elapsed < (opts.timeBudgetMs!! + 500), "Expert took ${elapsed}ms")
        assertNotNull(r.turn)
        assertTrue(r.depth >= 2, "should reach at least depth 2, got ${r.depth}")
    }

    // ─── Pas de coup légal → turn null ───────────────────────────────────────

    @Test
    fun `Mariama returns null turn when no legal moves`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                ".....",
                ".....",
                ".....",
            )
        )
        val r = Mariama.findBestMove(b, Color.X, FindBestMoveOptions(maxDepth = 2))
        assertEquals(null, r.turn)
    }

    // ─── Difficulty configs ──────────────────────────────────────────────────

    @Test
    fun `difficulty configs have expected depths`() {
        assertEquals(2, Difficulty.EASY.options.maxDepth)
        assertEquals(4, Difficulty.MEDIUM.options.maxDepth)
        assertEquals(6, Difficulty.HARD.options.maxDepth)
        assertEquals(3500, Difficulty.EXPERT.options.timeBudgetMs)
    }

    // ─── Hashing ─────────────────────────────────────────────────────────────

    @Test
    fun `transposition table hash differs for X turn vs O turn`() {
        val b = Board.initial()
        val hx = TranspositionTable.hash(b, Color.X)
        val ho = TranspositionTable.hash(b, Color.O)
        assertTrue(hx != ho, "hash should encode the turn color")
    }
}
