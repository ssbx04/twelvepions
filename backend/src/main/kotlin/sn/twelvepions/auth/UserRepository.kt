package sn.twelvepions.auth

import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface UserRepository : JpaRepository<User, UUID> {
    fun findByPhone(phone: String): User?
    fun existsByUsernameIgnoreCase(username: String): Boolean

    @Query("""
        SELECT u FROM User u
        WHERE u.username IS NOT NULL
          AND (LOWER(u.username) LIKE LOWER(CONCAT('%', :q, '%'))
            OR LOWER(u.fullName) LIKE LOWER(CONCAT('%', :q, '%')))
    """)
    fun searchByUsernameOrName(@Param("q") query: String, pageable: Pageable): List<User>
}
