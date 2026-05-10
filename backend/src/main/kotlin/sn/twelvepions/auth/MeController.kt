package sn.twelvepions.auth

import org.springframework.data.domain.PageRequest
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import sn.twelvepions.auth.dto.UserDto
import sn.twelvepions.game.GameRepository
import sn.twelvepions.game.dto.GameSummaryDto
import java.util.UUID

@RestController
@RequestMapping("/me")
class MeController(
    private val authService: AuthService,
    private val gameRepository: GameRepository,
) {
    @GetMapping
    fun me(@AuthenticationPrincipal userId: UUID): UserDto = authService.getUser(userId)

    @GetMapping("/games")
    fun recentGames(
        @AuthenticationPrincipal userId: UUID,
        @RequestParam(defaultValue = "5") limit: Int,
    ): List<GameSummaryDto> {
        val safeLimit = limit.coerceIn(1, 20)
        val games = gameRepository.findRecentFinishedByUser(userId, PageRequest.of(0, safeLimit))
        return games.map { g ->
            val isX = g.playerXId == userId
            val opponentId = if (isX) g.playerOId else g.playerXId
            val opponent = authService.getUser(opponentId)
            val result = when {
                g.winner == null -> "DRAW"
                (g.winner == "X") == isX -> "WIN"
                else -> "LOSS"
            }
            val eloChange = if (isX) g.eloChangeX ?: 0 else g.eloChangeO ?: 0
            GameSummaryDto(
                gameId = g.id.toString(),
                opponentUsername = opponent.username ?: opponent.phone,
                opponentElo = if (isX) g.playerOEloBefore else g.playerXEloBefore,
                result = result,
                eloChange = eloChange,
                endReason = g.endReason ?: "",
                finishedAt = g.finishedAt?.toString() ?: "",
            )
        }
    }
}
