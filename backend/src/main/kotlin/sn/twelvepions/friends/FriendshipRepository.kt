package sn.twelvepions.friends

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import java.util.UUID

interface FriendshipRepository : JpaRepository<Friendship, UUID> {

    @Query("""
        SELECT f FROM Friendship f
        WHERE f.status = 'ACCEPTED'
          AND (f.requesterId = :userId OR f.addresseeId = :userId)
    """)
    fun findAcceptedFriendsOf(@Param("userId") userId: UUID): List<Friendship>

    @Query("""
        SELECT f FROM Friendship f
        WHERE f.status = 'PENDING' AND f.addresseeId = :userId
    """)
    fun findPendingRequestsFor(@Param("userId") userId: UUID): List<Friendship>

    @Query("""
        SELECT f FROM Friendship f
        WHERE (f.requesterId = :a AND f.addresseeId = :b)
           OR (f.requesterId = :b AND f.addresseeId = :a)
    """)
    fun findBetween(@Param("a") a: UUID, @Param("b") b: UUID): Friendship?
}
