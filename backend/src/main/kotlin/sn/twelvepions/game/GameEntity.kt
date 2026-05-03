package sn.twelvepions.game

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.PreUpdate
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

enum class GameStatus { IN_PROGRESS, FINISHED }

enum class EndReason { CAPTURE_ALL, BLOCKED, ONE_VS_ONE, RESIGN }

@Entity
@Table(name = "games")
class GameEntity(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(name = "player_x_id", nullable = false)
    var playerXId: UUID,

    @Column(name = "player_o_id", nullable = false)
    var playerOId: UUID,

    @Column(nullable = false, length = 20)
    var status: String = GameStatus.IN_PROGRESS.name,

    /** Couleur dont c'est le tour : "X" ou "O". */
    @Column(nullable = false, length = 1)
    var turn: String = "X",

    /** Plateau sérialisé : 5 lignes séparées par '\n'. */
    @Column(nullable = false, columnDefinition = "TEXT")
    var board: String,

    /** Si une chaîne de captures est en cours, position "r,c" du pion qui doit continuer. */
    @Column(name = "must_continue_from", length = 5)
    var mustContinueFrom: String? = null,

    /** "X", "O" ou null (en cours / match nul). */
    @Column(length = 1)
    var winner: String? = null,

    @Column(name = "end_reason", length = 20)
    var endReason: String? = null,

    @Column(name = "player_x_elo_before", nullable = false)
    var playerXEloBefore: Int,

    @Column(name = "player_o_elo_before", nullable = false)
    var playerOEloBefore: Int,

    @Column(name = "elo_change_x")
    var eloChangeX: Int? = null,

    @Column(name = "elo_change_o")
    var eloChangeO: Int? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Column(name = "finished_at")
    var finishedAt: Instant? = null,
) {
    @PreUpdate
    fun onUpdate() { updatedAt = Instant.now() }
}
