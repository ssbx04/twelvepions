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

    @Query("""
        SELECT u FROM User u
        WHERE u.username IS NOT NULL
          AND u.id != :userId
          AND u.id NOT IN (
            SELECT CASE WHEN f.requesterId = :userId THEN f.addresseeId ELSE f.requesterId END
            FROM Friendship f
            WHERE f.requesterId = :userId OR f.addresseeId = :userId
          )
        ORDER BY u.elo DESC
    """)
    fun findSuggestedUsers(@Param("userId") userId: UUID, pageable: Pageable): List<User>
}
