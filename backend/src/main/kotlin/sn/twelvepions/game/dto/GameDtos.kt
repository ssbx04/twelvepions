package sn.twelvepions.game.dto

import sn.twelvepions.game.ai.dto.MoveDto

/** Snapshot d'état envoyé aux clients. */
data class GameStateDto(
    val gameId: String,
    val playerX: PlayerDto,
    val playerO: PlayerDto,
    val board: List<String>,
    val turn: String,
    val mustContinueFrom: String?,
    val ply: Int,
    val status: String,
    val winner: String?,
    val endReason: String?,
    val eloChange: EloChangeDto?,
)

data class PlayerDto(
    val id: String,
    val username: String,
    val elo: Int,
)

data class EloChangeDto(
    val x: Int,
    val o: Int,
)

/** Coup envoyé par un client. */
data class MoveSequenceDto(
    val sequence: List<MoveDto>,
)
