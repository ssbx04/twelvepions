package sn.twelvepions.game

import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import sn.twelvepions.auth.UserRepository
import sn.twelvepions.game.ai.dto.MoveDto
import sn.twelvepions.game.ai.dto.PositionDto
import sn.twelvepions.game.dto.EloChangeDto
import sn.twelvepions.game.dto.GameStateDto
import sn.twelvepions.game.dto.PlayerDto
import tools.jackson.databind.ObjectMapper
import tools.jackson.module.kotlin.readValue
import java.time.Instant
import java.util.UUID

/**
 * Cœur du gameplay online. Toutes les opérations sont transactionnelles
 * et utilisent [Rules] pour valider les coups (serveur autoritaire).
 */
@Service
class GameService(
    private val games: GameRepository,
    private val moves: GameMoveRepository,
    private val users: UserRepository,
    private val elo: EloService,
    private val mapper: ObjectMapper,
) {

    @Transactional
    fun createGame(playerXId: UUID, playerOId: UUID): GameStateDto {
        require(playerXId != playerOId) { "Cannot create game with same player on both sides" }
        val ux = users.findById(playerXId).orElseThrow { IllegalArgumentException("Player X not found") }
        val uo = users.findById(playerOId).orElseThrow { IllegalArgumentException("Player O not found") }

        val game = GameEntity(
            playerXId = playerXId,
            playerOId = playerOId,
            board = serializeBoard(Board.initial()),
            playerXEloBefore = ux.elo,
            playerOEloBefore = uo.elo,
        )
        games.save(game)
        return toDto(game)
    }

    fun getState(gameId: UUID): GameStateDto {
        val game = games.findById(gameId).orElseThrow { GameNotFoundException() }
        return toDto(game)
    }

    /**
     * Applique un tour (séquence de coups) joué par [userId] sur la partie [gameId].
     * Valide le tour contre la liste des tours légaux (capture forcée, chaîne, etc.).
     * Si la partie se termine, met à jour l'ELO et stocke la fin.
     */
    @Transactional
    fun applyMove(gameId: UUID, userId: UUID, sequence: List<MoveDto>): GameStateDto {
        val game = games.findById(gameId).orElseThrow { GameNotFoundException() }
        if (game.status != GameStatus.IN_PROGRESS.name) throw GameNotActiveException()

        val playerColor = colorOf(game, userId) ?: throw NotAPlayerException()
        if (game.turn != playerColor.name) throw NotYourTurnException()

        val board = parseBoard(game.board)
        val legalTurns = Rules.enumerateTurns(board, playerColor)
        val turn = sequenceToTurn(sequence)
        if (legalTurns.none { it == turn }) {
            throw IllegalMoveException("ce coup ne fait pas partie des tours légaux")
        }

        // Applique tous les coups de la séquence + promotion solo en fin de tour.
        var newBoard = board
        for (m in turn.sequence) newBoard = Rules.applyMove(newBoard, m)
        newBoard = Rules.autoPromoteLast(newBoard)

        // Persiste le coup.
        val ply = moves.countByGameId(gameId).toInt()
        moves.save(
            GameMoveEntity(
                gameId = gameId,
                ply = ply,
                player = playerColor.name,
                sequenceJson = mapper.writeValueAsString(sequence),
            ),
        )

        // Met à jour l'état du plateau.
        game.board = serializeBoard(newBoard)
        game.mustContinueFrom = null

        // Vérifie l'issue.
        val outcome = Rules.computeOutcome(newBoard, playerColor)
        if (outcome != null) {
            handleEnd(game, outcome)
        } else {
            game.turn = playerColor.opponent().name
        }

        games.save(game)
        return toDto(game)
    }

    @Transactional
    fun resign(gameId: UUID, userId: UUID): GameStateDto {
        val game = games.findById(gameId).orElseThrow { GameNotFoundException() }
        if (game.status != GameStatus.IN_PROGRESS.name) throw GameNotActiveException()

        val resignerColor = colorOf(game, userId) ?: throw NotAPlayerException()
        val winnerColor = resignerColor.opponent()

        game.winner = winnerColor.name
        game.endReason = EndReason.RESIGN.name
        game.status = GameStatus.FINISHED.name
        game.finishedAt = Instant.now()
        applyEloUpdate(game)
        games.save(game)

        return toDto(game)
    }

    fun playersOf(gameId: UUID): Pair<UUID, UUID> {
        val game = games.findById(gameId).orElseThrow { GameNotFoundException() }
        return game.playerXId to game.playerOId
    }

    // ─── Privé ────────────────────────────────────────────────────────────────

    private fun colorOf(game: GameEntity, userId: UUID): Color? = when (userId) {
        game.playerXId -> Color.X
        game.playerOId -> Color.O
        else -> null
    }

    private fun handleEnd(game: GameEntity, outcome: Outcome) {
        game.status = GameStatus.FINISHED.name
        game.finishedAt = Instant.now()
        when (outcome) {
            is Outcome.Win -> {
                game.winner = outcome.winner.name
                game.endReason = when (outcome.reason) {
                    WinReason.CAPTURE_ALL -> EndReason.CAPTURE_ALL.name
                    WinReason.BLOCKED -> EndReason.BLOCKED.name
                }
            }
            is Outcome.Draw -> {
                game.winner = null
                game.endReason = EndReason.ONE_VS_ONE.name
            }
        }
        applyEloUpdate(game)
    }

    private fun applyEloUpdate(game: GameEntity) {
        val (deltaX, deltaO) = elo.applyResult(game.playerXId, game.playerOId, game.winner)
        game.eloChangeX = deltaX
        game.eloChangeO = deltaO
    }

    private fun sequenceToTurn(seq: List<MoveDto>): Turn {
        require(seq.isNotEmpty()) { "Empty move sequence" }
        return Turn(
            sequence = seq.map { dto ->
                Move(
                    from = Position(dto.from.r, dto.from.c),
                    to = Position(dto.to.r, dto.to.c),
                    captured = dto.captured?.let { Position(it.r, it.c) },
                )
            },
        )
    }

    private fun toDto(game: GameEntity): GameStateDto {
        val ux = users.findById(game.playerXId).orElseThrow { IllegalStateException("Player X gone") }
        val uo = users.findById(game.playerOId).orElseThrow { IllegalStateException("Player O gone") }
        val ply = moves.countByGameId(game.id).toInt()
        val eloChange = if (game.eloChangeX != null && game.eloChangeO != null) {
            EloChangeDto(game.eloChangeX!!, game.eloChangeO!!)
        } else null
        return GameStateDto(
            gameId = game.id.toString(),
            playerX = PlayerDto(ux.id.toString(), ux.username ?: "(anon)", ux.elo),
            playerO = PlayerDto(uo.id.toString(), uo.username ?: "(anon)", uo.elo),
            board = game.board.split('\n'),
            turn = game.turn,
            mustContinueFrom = game.mustContinueFrom,
            ply = ply,
            status = game.status,
            winner = game.winner,
            endReason = game.endReason,
            eloChange = eloChange,
        )
    }

    companion object {
        fun serializeBoard(board: Board): String {
            val sb = StringBuilder()
            for (r in 0 until BOARD_SIZE) {
                if (r > 0) sb.append('\n')
                for (c in 0 until BOARD_SIZE) {
                    val p = board.at(r, c)
                    sb.append(
                        when {
                            p == null -> '.'
                            p.color == Color.X && !p.dame -> 'X'
                            p.color == Color.X && p.dame -> 'x'
                            p.color == Color.O && !p.dame -> 'O'
                            else -> 'o'
                        },
                    )
                }
            }
            return sb.toString()
        }

        fun parseBoard(serialized: String): Board = Board.parse(serialized.split('\n'))
    }
}
