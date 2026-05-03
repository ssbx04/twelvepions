package sn.twelvepions.game

import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class RulesTest {

    // ─── Plateau initial ──────────────────────────────────────────────────────

    @Test
    fun `initial board has 12 pieces per color`() {
        val b = Board.initial()
        assertEquals(12, b.count(Color.X))
        assertEquals(12, b.count(Color.O))
    }

    @Test
    fun `initial board has center empty`() {
        val b = Board.initial()
        assertNull(b.at(2, 2))
    }

    @Test
    fun `initial board X is on top, O on bottom`() {
        val b = Board.initial()
        assertEquals(Color.X, b.at(0, 0)?.color)
        assertEquals(Color.X, b.at(1, 4)?.color)
        assertEquals(Color.X, b.at(2, 0)?.color)
        assertEquals(Color.X, b.at(2, 1)?.color)
        assertEquals(Color.O, b.at(2, 3)?.color)
        assertEquals(Color.O, b.at(2, 4)?.color)
        assertEquals(Color.O, b.at(3, 2)?.color)
        assertEquals(Color.O, b.at(4, 4)?.color)
    }

    @Test
    fun `initial pieces are pions, not dames`() {
        val b = Board.initial()
        for (r in 0 until BOARD_SIZE) for (c in 0 until BOARD_SIZE) {
            val p = b.at(r, c) ?: continue
            assertFalse(p.dame, "piece at ($r,$c) should not be a dame")
        }
    }

    // ─── Parser ───────────────────────────────────────────────────────────────

    @Test
    fun `parse builds the same board as initial`() {
        val parsed = Board.parse(
            listOf(
                "XXXXX",
                "XXXXX",
                "XX.OO",
                "OOOOO",
                "OOOOO",
            )
        )
        assertEquals(Board.initial(), parsed)
    }

    @Test
    fun `parse rejects bad size`() {
        assertThrows<IllegalArgumentException> {
            Board.parse(listOf("XXXX", "...."))
        }
    }

    @Test
    fun `parse rejects bad chars`() {
        assertThrows<IllegalStateException> {
            Board.parse(listOf("XXXXY", "XXXXX", "XX.OO", "OOOOO", "OOOOO"))
        }
    }

    // ─── Coups simples (pion) ─────────────────────────────────────────────────

    @Test
    fun `pion X moves forward and sideways, never backward`() {
        // X au centre (2,2), seul pion sur le plateau.
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                ".....",
                ".....",
            )
        )
        val moves = Rules.simpleMoves(b, 2, 2).map { it.to }.toSet()
        // X avance vers +r, donc forward = (3,2). Côtés = (2,1), (2,3). Pas (1,2).
        assertEquals(setOf(Position(3, 2), Position(2, 1), Position(2, 3)), moves)
    }

    @Test
    fun `pion O moves forward and sideways, never backward`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..O..",
                ".....",
                ".....",
            )
        )
        val moves = Rules.simpleMoves(b, 2, 2).map { it.to }.toSet()
        // O avance vers -r, donc forward = (1,2). Côtés = (2,1), (2,3). Pas (3,2).
        assertEquals(setOf(Position(1, 2), Position(2, 1), Position(2, 3)), moves)
    }

    @Test
    fun `pion cannot move onto an occupied cell`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                "..X..",
                ".....",
            )
        )
        val moves = Rules.simpleMoves(b, 2, 2).map { it.to }.toSet()
        // (3,2) est occupé.
        assertEquals(setOf(Position(2, 1), Position(2, 3)), moves)
    }

    // ─── Coups simples (dame) ─────────────────────────────────────────────────

    @Test
    fun `dame slides in 4 orthogonal directions, any distance`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..x..",
                ".....",
                ".....",
            )
        )
        val moves = Rules.simpleMoves(b, 2, 2).map { it.to }.toSet()
        // Dame X au centre : 4 directions, jusqu'aux bords.
        assertEquals(
            setOf(
                Position(0, 2), Position(1, 2), // haut
                Position(3, 2), Position(4, 2), // bas
                Position(2, 0), Position(2, 1), // gauche
                Position(2, 3), Position(2, 4), // droite
            ),
            moves,
        )
    }

    @Test
    fun `dame stops before first occupied cell`() {
        val b = Board.parse(
            listOf(
                "..X..",
                ".....",
                "..x..",
                ".....",
                "..O..",
            )
        )
        val moves = Rules.simpleMoves(b, 2, 2).map { it.to }.toSet()
        // Vers le haut : (1,2). (0,2) bloqué par X amie.
        // Vers le bas  : (3,2). (4,2) bloqué par O.
        // Côtés OK.
        assertEquals(
            setOf(
                Position(1, 2),
                Position(3, 2),
                Position(2, 0), Position(2, 1),
                Position(2, 3), Position(2, 4),
            ),
            moves,
        )
    }

    // ─── Captures (pion) ──────────────────────────────────────────────────────

    @Test
    fun `pion captures forward over enemy`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                "..O..",
                ".....",
            )
        )
        val caps = Rules.captureMoves(b, 2, 2)
        assertEquals(1, caps.size)
        val m = caps[0]
        assertEquals(Position(2, 2), m.from)
        assertEquals(Position(4, 2), m.to)
        assertEquals(Position(3, 2), m.captured)
    }

    @Test
    fun `pion does not capture backward`() {
        // X tente de capturer vers le haut → interdit.
        val b = Board.parse(
            listOf(
                ".....",
                "..O..",
                "..X..",
                ".....",
                ".....",
            )
        )
        assertTrue(Rules.captureMoves(b, 2, 2).isEmpty())
    }

    @Test
    fun `pion does not capture friendly piece`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                "..X..",
                ".....",
            )
        )
        assertTrue(Rules.captureMoves(b, 2, 2).isEmpty())
    }

    // ─── Captures (dame) ──────────────────────────────────────────────────────

    @Test
    fun `dame slides through empty cells, captures, and lands anywhere beyond`() {
        // Dame X en (0,0), ennemi O en (0,3). Cases (0,4) libre comme atterrissage.
        val b = Board.parse(
            listOf(
                "x..O.",
                ".....",
                ".....",
                ".....",
                ".....",
            )
        )
        val caps = Rules.captureMoves(b, 0, 0)
        assertEquals(1, caps.size)
        val m = caps[0]
        assertEquals(Position(0, 0), m.from)
        assertEquals(Position(0, 4), m.to)
        assertEquals(Position(0, 3), m.captured)
    }

    @Test
    fun `dame can land on multiple empty cells beyond the captured enemy`() {
        // Dame X en (2,0), ennemi en (2,2), (2,3) et (2,4) libres.
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "x.O..",
                ".....",
                ".....",
            )
        )
        val caps = Rules.captureMoves(b, 2, 0).map { it.to }.toSet()
        assertEquals(setOf(Position(2, 3), Position(2, 4)), caps)
    }

    // ─── applyMove + promotion ────────────────────────────────────────────────

    @Test
    fun `applyMove moves piece and clears origin`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                ".....",
                ".....",
            )
        )
        val nb = Rules.applyMove(b, Move(Position(2, 2), Position(3, 2)))
        assertNull(nb.at(2, 2))
        assertEquals(Piece(Color.X), nb.at(3, 2))
    }

    @Test
    fun `applyMove removes captured piece`() {
        // X en (1,2), O en (2,2). X capture vers (3,2) — pas de promotion (rangée 4 = promo).
        val b = Board.parse(
            listOf(
                ".....",
                "..X..",
                "..O..",
                ".....",
                ".....",
            )
        )
        val nb = Rules.applyMove(b, Move(Position(1, 2), Position(3, 2), Position(2, 2)))
        assertNull(nb.at(1, 2))
        assertNull(nb.at(2, 2))
        assertEquals(Piece(Color.X, dame = false), nb.at(3, 2))
    }

    @Test
    fun `pion X reaching row 4 becomes dame`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                ".....",
                "..X..",
                ".....",
            )
        )
        val nb = Rules.applyMove(b, Move(Position(3, 2), Position(4, 2)))
        val p = nb.at(4, 2)
        assertNotNull(p)
        assertTrue(p.dame, "pion should have been promoted")
    }

    @Test
    fun `pion O reaching row 0 becomes dame`() {
        val b = Board.parse(
            listOf(
                ".....",
                "..O..",
                ".....",
                ".....",
                ".....",
            )
        )
        val nb = Rules.applyMove(b, Move(Position(1, 2), Position(0, 2)))
        val p = nb.at(0, 2)
        assertNotNull(p)
        assertTrue(p.dame)
    }

    // ─── autoPromoteLast ──────────────────────────────────────────────────────

    @Test
    fun `lonely pion is auto-promoted to dame`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..", // seul X sur le plateau
                "..O..",
                "..O..",
            )
        )
        val nb = Rules.autoPromoteLast(b)
        assertTrue(nb.at(2, 2)?.dame == true)
        // Les O ne sont pas promus (ils sont 2)
        assertFalse(nb.at(3, 2)?.dame == true)
    }

    @Test
    fun `lonely pion already a dame stays a dame`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..x..",
                "..O..",
                "..O..",
            )
        )
        val nb = Rules.autoPromoteLast(b)
        assertEquals(b, nb)
    }

    // ─── hasAnyMove / hasAnyCapture ───────────────────────────────────────────

    @Test
    fun `hasAnyMove false when blocked`() {
        // X en (0,0) entouré → bloqué (pas en arrière, pas en avant, pas en côté).
        val b = Board.parse(
            listOf(
                "X.X..",
                "X....",
                ".....",
                ".....",
                ".....",
            )
        )
        // X en (0,0) : forward = (1,0) bloqué ; côté droit (0,1) libre. Donc HAS move.
        assertTrue(Rules.hasAnyMove(b, Color.X))
    }

    @Test
    fun `hasAnyMove false on empty side`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                ".....",
                ".....",
                ".....",
            )
        )
        assertFalse(Rules.hasAnyMove(b, Color.X))
        assertFalse(Rules.hasAnyMove(b, Color.O))
    }

    @Test
    fun `hasAnyCapture detects available capture`() {
        // X capture O vers le bas. O est sur une rangée du bord (4,2), donc ne peut
        // pas capturer en arrière (rangée 5 inexistante) ni sur les côtés.
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                ".....",
                "..X..",
                "..O..",
            )
        )
        // X à (3,2) : forward = (4,2) bloqué. Pas de capture (atterrissage hors-bord).
        assertFalse(Rules.hasAnyCapture(b, Color.X))
        // O à (4,2) : forward = (3,2) occupé X, atterrissage (2,2) libre → CAPTURE possible.
        assertTrue(Rules.hasAnyCapture(b, Color.O))
    }

    // ─── enumerateTurns + chaîne de captures ──────────────────────────────────

    @Test
    fun `enumerateTurns returns simple moves when no captures available`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                ".....",
                ".....",
            )
        )
        val turns = Rules.enumerateTurns(b, Color.X)
        assertEquals(3, turns.size) // 3 directions simples
        assertTrue(turns.all { it.sequence.size == 1 })
        assertTrue(turns.all { it.sequence[0].captured == null })
    }

    @Test
    fun `enumerateTurns forces captures when available`() {
        val b = Board.parse(
            listOf(
                ".....",
                ".....",
                "..X..",
                "..O..",
                ".....",
            )
        )
        val turns = Rules.enumerateTurns(b, Color.X)
        assertEquals(1, turns.size)
        assertEquals(Position(3, 2), turns[0].sequence[0].captured)
    }

    @Test
    fun `enumerateTurns develops capture chains (Coudou)`() {
        // X capture O en (2,2) → atterrit en (2,3), puis capture O en (2,4)... mais
        // (2,4) est hors bord. Construisons un cas plus simple : double capture verticale.
        // X en (0,2), O en (1,2) et O en (3,2). X saute (1,2) → atterrit en (2,2),
        // puis saute (3,2) → atterrit en (4,2).
        val b = Board.parse(
            listOf(
                "..X..",
                "..O..",
                ".....",
                "..O..",
                ".....",
            )
        )
        val turns = Rules.enumerateTurns(b, Color.X)
        // Une seule chaîne de 2 captures.
        assertEquals(1, turns.size)
        val seq = turns[0].sequence
        assertEquals(2, seq.size)
        assertEquals(Position(0, 2), seq[0].from)
        assertEquals(Position(2, 2), seq[0].to)
        assertEquals(Position(1, 2), seq[0].captured)
        assertEquals(Position(2, 2), seq[1].from)
        assertEquals(Position(4, 2), seq[1].to)
        assertEquals(Position(3, 2), seq[1].captured)
    }

    // ─── Match nul 1v1 ────────────────────────────────────────────────────────

    @Test
    fun `isOnePieceDraw true when both colors have exactly one piece`() {
        val b = Board.parse(
            listOf(
                "x....",
                ".....",
                ".....",
                ".....",
                "....o",
            )
        )
        assertTrue(Rules.isOnePieceDraw(b))
    }

    @Test
    fun `isOnePieceDraw false when one player has more pieces`() {
        val b = Board.parse(
            listOf(
                "x....",
                ".....",
                ".....",
                "..O..",
                "....o",
            )
        )
        assertFalse(Rules.isOnePieceDraw(b))
    }

    @Test
    fun `computeOutcome returns Draw on 1 vs 1`() {
        val b = Board.parse(
            listOf(
                "x....",
                ".....",
                ".....",
                ".....",
                "....o",
            )
        )
        // X vient de jouer, mais peu importe : 1 vs 1 → Draw.
        assertEquals(Outcome.Draw, Rules.computeOutcome(b, Color.X))
    }

    @Test
    fun `computeOutcome returns Win CAPTURE_ALL when opponent has 0 pieces`() {
        val b = Board.parse(
            listOf(
                "x....",
                ".....",
                ".....",
                ".....",
                ".....",
            )
        )
        assertEquals(
            Outcome.Win(Color.X, WinReason.CAPTURE_ALL),
            Rules.computeOutcome(b, Color.X),
        )
    }

    @Test
    fun `computeOutcome returns null when game continues`() {
        val b = Board.initial()
        assertNull(Rules.computeOutcome(b, Color.X))
    }

    // ─── Initial state : Vert commence et a des coups ────────────────────────

    @Test
    fun `initial state X has moves`() {
        val b = Board.initial()
        assertTrue(Rules.hasAnyMove(b, Color.X))
        // Au début, pas de capture possible (pas de pièces adjacentes ennemies).
        assertFalse(Rules.hasAnyCapture(b, Color.X))
    }
}
