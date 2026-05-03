package sn.twelvepions.game

import io.swagger.v3.oas.annotations.Operation
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import sn.twelvepions.game.ai.Mariama
import sn.twelvepions.game.ai.dto.AiMoveRequest
import sn.twelvepions.game.ai.dto.AiMoveResponse
import sn.twelvepions.game.ai.dto.MoveDto
import sn.twelvepions.game.ai.dto.PositionDto

@RestController
@RequestMapping("/ai")
@Tag(name = "AI (Mariama)", description = "Endpoints pour jouer contre Mariama, l'IA")
class AiController {

    @Operation(
        summary = "Calcule le meilleur coup pour la couleur donnée",
        description = "Plateau encodé en 5 lignes de 5 caractères : `X` pion vert, `x` dame verte, " +
            "`O` pion rouge, `o` dame rouge, `.` case vide.",
    )
    @PostMapping("/move")
    fun move(@Valid @RequestBody req: AiMoveRequest): AiMoveResponse {
        val board = Board.parse(req.board)
        val result = Mariama.findBestMove(board, req.color, req.difficulty.options)
        return AiMoveResponse(
            sequence = result.turn?.sequence?.map { m ->
                MoveDto(
                    from = PositionDto(m.from.r, m.from.c),
                    to = PositionDto(m.to.r, m.to.c),
                    captured = m.captured?.let { PositionDto(it.r, it.c) },
                )
            },
            score = result.score,
            depth = result.depth,
        )
    }
}
