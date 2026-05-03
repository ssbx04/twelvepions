package sn.twelvepions.auth

import org.springframework.data.jpa.repository.JpaRepository
import java.util.UUID

interface UserRepository : JpaRepository<User, UUID> {
    fun findByPhone(phone: String): User?
    fun existsByUsernameIgnoreCase(username: String): Boolean
}
