package sn.twelvepions.friends

import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import sn.twelvepions.auth.UserRepository
import sn.twelvepions.game.GameService
import sn.twelvepions.ws.SessionRegistry
import tools.jackson.databind.ObjectMapper
import java.util.UUID

@Service
class FriendshipService(
    private val friendships: FriendshipRepository,
    private val users: UserRepository,
    private val sessions: SessionRegistry,
    private val gameService: GameService,
    private val mapper: ObjectMapper,
) {

    fun getFriends(userId: UUID): List<FriendDto> {
        return friendships.findAcceptedFriendsOf(userId).map { f ->
            val friendId = if (f.requesterId == userId) f.addresseeId else f.requesterId
            toFriendDto(friendId)
        }
    }

    fun getPendingRequests(userId: UUID): List<FriendRequestDto> {
        return friendships.findPendingRequestsFor(userId).map { f ->
            FriendRequestDto(
                requestId = f.id.toString(),
                from = toFriendDto(f.requesterId),
                createdAt = f.createdAt.toString(),
            )
        }
    }

    @Transactional
    fun sendRequest(requesterId: UUID, targetId: UUID) {
        require(requesterId != targetId) { "Cannot add yourself" }
        val existing = friendships.findBetween(requesterId, targetId)
        require(existing == null) { "Friendship already exists or pending" }
        val target = users.findById(targetId).orElseThrow { IllegalArgumentException("User not found") }
        val requester = users.findById(requesterId).orElseThrow()
        val saved = friendships.save(Friendship(requesterId = requesterId, addresseeId = targetId))

        // Push WS si la cible est connectée
        sessions.send(targetId, mapper.writeValueAsString(mapOf(
            "type" to "friend.request.received",
            "requestId" to saved.id.toString(),
            "fromId" to requesterId.toString(),
            "fromUsername" to (requester.username ?: requester.phone),
            "fromElo" to requester.elo,
        )))
    }

    @Transactional
    fun acceptRequest(userId: UUID, requestId: UUID) {
        val f = friendships.findById(requestId).orElseThrow { IllegalArgumentException("Request not found") }
        require(f.addresseeId == userId) { "Not your request" }
        require(f.status == "PENDING") { "Request already processed" }
        f.status = "ACCEPTED"
        friendships.save(f)

        // Notifier le demandeur que sa demande a été acceptée
        val accepter = users.findById(userId).orElseThrow()
        sessions.send(f.requesterId, mapper.writeValueAsString(mapOf(
            "type" to "friend.request.accepted",
            "requestId" to requestId.toString(),
            "byUsername" to (accepter.username ?: accepter.phone),
            "byElo" to accepter.elo,
        )))
    }

    @Transactional
    fun declineOrRemove(userId: UUID, targetId: UUID) {
        val f = friendships.findBetween(userId, targetId)
            ?: throw IllegalArgumentException("No friendship found")
        require(f.requesterId == userId || f.addresseeId == userId) { "Not your friendship" }
        friendships.delete(f)
    }

    fun searchUsers(query: String, currentUserId: UUID): List<UserSearchResultDto> {
        if (query.length < 2) return emptyList()
        val results = users.searchByUsernameOrName(query, PageRequest.of(0, 20))
        return results
            .filter { it.id != currentUserId }
            .map { user ->
                val f = friendships.findBetween(currentUserId, user.id)
                val status = when {
                    f == null -> "NONE"
                    f.status == "ACCEPTED" -> "FRIENDS"
                    f.requesterId == currentUserId -> "PENDING_SENT"
                    else -> "PENDING_RECEIVED"
                }
                UserSearchResultDto(
                    id = user.id.toString(),
                    username = user.username ?: user.phone,
                    fullName = user.fullName,
                    elo = user.elo,
                    friendshipStatus = status,
                )
            }
    }

    private fun toFriendDto(userId: UUID): FriendDto {
        val user = users.findById(userId).orElseThrow()
        val presence = when {
            gameService.findActiveGameOf(userId) != null -> "IN_GAME"
            sessions.get(userId) != null -> "ONLINE"
            else -> "OFFLINE"
        }
        return FriendDto(
            id = user.id.toString(),
            username = user.username ?: user.phone,
            fullName = user.fullName,
            elo = user.elo,
            presence = presence,
        )
    }
}
