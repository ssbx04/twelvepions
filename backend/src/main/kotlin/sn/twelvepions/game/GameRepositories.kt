package sn.twelvepions.game

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface GameRepository : JpaRepository<GameEntity, UUID> {
    fun findByPlayerXIdOrPlayerOIdOrderByCreatedAtDesc(
        playerXId: UUID,
        playerOId: UUID,
    ): List<GameEntity>
}

interface GameMoveRepository : JpaRepository<GameMoveEntity, Long> {
    fun countByGameId(gameId: UUID): Long
    fun findByGameIdOrderByPlyAsc(gameId: UUID): List<GameMoveEntity>
}
