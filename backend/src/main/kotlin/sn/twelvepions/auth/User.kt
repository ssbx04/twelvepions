package sn.twelvepions.auth

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.PreUpdate
import jakarta.persistence.Table
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "users")
class User(
    @Id
    var id: UUID = UUID.randomUUID(),

    @Column(nullable = false, unique = true)
    var phone: String,

    @Column(name = "full_name")
    var fullName: String? = null,

    @Column
    var username: String? = null,

    @Enumerated(EnumType.STRING)
    @Column
    var level: UserLevel? = null,

    @Column(nullable = false)
    var elo: Int = 1000,

    @Column(name = "fcm_token")
    var fcmToken: String? = null,

    @Column(name = "created_at", nullable = false, updatable = false)
    var createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),
) {
    /** True si tous les champs requis post-signup sont remplis. */
    val profileComplete: Boolean
        get() = fullName != null && username != null && level != null

    @PreUpdate
    fun onUpdate() {
        updatedAt = Instant.now()
    }
}
