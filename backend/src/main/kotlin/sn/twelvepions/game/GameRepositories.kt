package sn.twelvepions.game

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.domain.Pageable
import org.springframework.data.repository.query.Param
import java.util.UUID

interface GameRepository : JpaRepository<GameEntity, UUID> {
    fun findByPlayerXIdOrPlayerOIdOrderByCreatedAtDesc(
        playerXId: UUID,
        playerOId: UUID,
    ): List<GameEntity>

    @Query(
        "SELECT g FROM GameEntity g " +
            "WHERE g.status = 'IN_PROGRESS' AND (g.playerXId = :uid OR g.playerOId = :uid) " +
            "ORDER BY g.createdAt DESC",
    )
    fun findActiveByUser(@Param("uid") userId: UUID): List<GameEntity>

    @Query(
        "SELECT g FROM GameEntity g " +
            "WHERE g.status = 'FINISHED' AND (g.playerXId = :uid OR g.playerOId = :uid) " +
            "ORDER BY g.finishedAt DESC",
    )
    fun findRecentFinishedByUser(@Param("uid") userId: UUID, pageable: Pageable): List<GameEntity>
}

interface GameMoveRepository : JpaRepository<GameMoveEntity, Long> {
    fun countByGameId(gameId: UUID): Long
    fun findByGameIdOrderByPlyAsc(gameId: UUID): List<GameMoveEntity>
}
