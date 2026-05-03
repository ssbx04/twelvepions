package sn.twelvepions.game.ai.dto

import jakarta.validation.constraints.NotEmpty
import jakarta.validation.constraints.Size
import sn.twelvepions.game.Color
import sn.twelvepions.game.ai.Difficulty

/**
 * Requête : plateau encodé sous forme de 5 chaînes de 5 caractères
 * (`X`/`x`/`O`/`o`/`.`), couleur dont c'est le tour, niveau de difficulté.
 */
data class AiMoveRequest(
    @field:NotEmpty
    @field:Size(min = 5, max = 5, message = "Le plateau doit avoir exactement 5 lignes")
    val board: List<String>,
    val color: Color,
    val difficulty: Difficulty,
)

/** Position simple. */
data class PositionDto(val r: Int, val c: Int)

/** Coup unique. */
data class MoveDto(val from: PositionDto, val to: PositionDto, val captured: PositionDto?)

/** Résultat : tour complet (séquence de coups), score d'éval, profondeur atteinte. */
data class AiMoveResponse(
    val sequence: List<MoveDto>?,
    val score: Int,
    val depth: Int,
)
