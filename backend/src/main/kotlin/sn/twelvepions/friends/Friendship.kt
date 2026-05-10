package sn.twelvepions.friends

import jakarta.persistence.*
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "friendships")
class Friendship(
    @Id val id: UUID = UUID.randomUUID(),
    @Column(nullable = false) val requesterId: UUID,
    @Column(nullable = false) val addresseeId: UUID,
    @Column(nullable = false) var status: String = "PENDING",
    @Column(nullable = false) val createdAt: Instant = Instant.now(),
)
