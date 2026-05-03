package sn.twelvepions.game

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "game_moves")
class GameMoveEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    var id: Long? = null,

    @Column(name = "game_id", nullable = false)
    var gameId: UUID,

    @Column(nullable = false)
    var ply: Int,

    @Column(nullable = false, length = 1)
    var player: String,

    /** JSON de la séquence : `[{from, to, captured}, ...]`. */
    @Column(name = "sequence_json", nullable = false, columnDefinition = "TEXT")
    var sequenceJson: String,

    @Column(name = "played_at", nullable = false)
    var playedAt: Instant = Instant.now(),
)
