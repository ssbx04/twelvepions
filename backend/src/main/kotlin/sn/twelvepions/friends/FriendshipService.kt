package sn.twelvepions.friends

import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import sn.twelvepions.auth.UserRepository
import sn.twelvepions.config.FcmService
import sn.twelvepions.game.GameService
import sn.twelvepions.ws.SessionRegistry
import tools.jackson.databind.ObjectMapper
import java.util.UUID

private val MARIAMA_ID: UUID = UUID(0, 0)

@Service
class FriendshipService(
    private val friendships: FriendshipRepository,
    private val users: UserRepository,
    private val sessions: SessionRegistry,
    private val gameService: GameService,
    private val fcm: FcmService,
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
        require(targetId != MARIAMA_ID) { "Cannot add Mariama as a friend" }
        val existing = friendships.findBetween(requesterId, targetId)
        require(existing == null) { "Friendship already exists or pending" }
        val target = users.findById(targetId).orElseThrow { IllegalArgumentException("User not found") }
        val requester = users.findById(requesterId).orElseThrow()
        val saved = friendships.save(Friendship(requesterId = requesterId, addresseeId = targetId))

        val senderName = requester.username ?: requester.phone
        if (sessions.get(targetId) != null) {
            sessions.send(targetId, mapper.writeValueAsString(mapOf(
                "type" to "friend.request.received",
                "requestId" to saved.id.toString(),
                "fromId" to requesterId.toString(),
                "fromUsername" to senderName,
                "fromElo" to requester.elo,
            )))
        } else {
            fcm.sendToUser(targetId, "12 Pions", "$senderName vous a envoyé une demande d'ami !",
                mapOf("type" to "friend_request", "requestId" to saved.id.toString()))
        }
    }

    @Transactional
    fun acceptRequest(userId: UUID, requestId: UUID) {
        val f = friendships.findById(requestId).orElseThrow { IllegalArgumentException("Request not found") }
        require(f.addresseeId == userId) { "Not your request" }
        require(f.status == "PENDING") { "Request already processed" }
        f.status = "ACCEPTED"
        friendships.save(f)

        val accepter = users.findById(userId).orElseThrow()
        val accepterName = accepter.username ?: accepter.phone
        if (sessions.get(f.requesterId) != null) {
            sessions.send(f.requesterId, mapper.writeValueAsString(mapOf(
                "type" to "friend.request.accepted",
                "requestId" to requestId.toString(),
                "byUsername" to accepterName,
                "byElo" to accepter.elo,
            )))
        } else {
            fcm.sendToUser(f.requesterId, "12 Pions", "$accepterName a accepté votre demande d'ami !",
                mapOf("type" to "friend_accepted"))
        }
    }

    @Transactional
    fun declineOrRemove(userId: UUID, targetId: UUID) {
        val f = friendships.findBetween(userId, targetId)
            ?: throw IllegalArgumentException("No friendship found")
        require(f.requesterId == userId || f.addresseeId == userId) { "Not your friendship" }
        friendships.delete(f)
    }

    fun getSuggestions(userId: UUID): List<UserSearchResultDto> {
        return users.findSuggestedUsers(userId, PageRequest.of(0, 10)).map { user ->
            UserSearchResultDto(
                id = user.id.toString(),
                username = user.username ?: user.phone,
                fullName = user.fullName,
                elo = user.elo,
                friendshipStatus = "NONE",
            )
        }
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
