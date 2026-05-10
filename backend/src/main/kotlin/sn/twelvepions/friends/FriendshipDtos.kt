package sn.twelvepions.friends

data class FriendDto(
    val id: String,
    val username: String,
    val fullName: String?,
    val elo: Int,
    val presence: String,   // ONLINE | IN_GAME | OFFLINE
)

data class FriendRequestDto(
    val requestId: String,
    val from: FriendDto,
    val createdAt: String,
)

data class UserSearchResultDto(
    val id: String,
    val username: String,
    val fullName: String?,
    val elo: Int,
    val friendshipStatus: String,   // NONE | PENDING_SENT | PENDING_RECEIVED | FRIENDS
)
