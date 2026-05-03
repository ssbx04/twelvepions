package sn.twelvepions.game.ai

/**
 * Options pour [Mariama.findBestMove].
 *
 * - [maxDepth]      : profondeur maximale (en demi-coups). Pour Expert, sert de limite à
 *                     l'iterative deepening.
 * - [timeBudgetMs]  : budget temps en ms. Si non null, active l'iterative deepening
 *                     (de [startDepth] à [maxDepth]) et coupe la recherche au timeout.
 * - [startDepth]    : profondeur de départ pour l'iterative deepening.
 */
data class FindBestMoveOptions(
    val maxDepth: Int,
    val timeBudgetMs: Long? = null,
    val startDepth: Int = 2,
)

/** 4 niveaux de difficulté de Mariama. */
enum class Difficulty(val options: FindBestMoveOptions) {
    EASY(FindBestMoveOptions(maxDepth = 2)),
    MEDIUM(FindBestMoveOptions(maxDepth = 4)),
    HARD(FindBestMoveOptions(maxDepth = 6)),
    EXPERT(FindBestMoveOptions(maxDepth = 24, timeBudgetMs = 3500, startDepth = 2)),
}
