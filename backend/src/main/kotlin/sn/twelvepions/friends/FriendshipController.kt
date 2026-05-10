package sn.twelvepions.friends

import org.springframework.http.ResponseEntity
import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping
class FriendshipController(private val service: FriendshipService) {

    @GetMapping("/friends")
    fun getFriends(@AuthenticationPrincipal userId: UUID): List<FriendDto> =
        service.getFriends(userId)

    @GetMapping("/friends/requests")
    fun getRequests(@AuthenticationPrincipal userId: UUID): List<FriendRequestDto> =
        service.getPendingRequests(userId)

    @PostMapping("/friends/request")
    fun sendRequest(
        @AuthenticationPrincipal userId: UUID,
        @RequestParam targetId: UUID,
    ): ResponseEntity<Unit> {
        service.sendRequest(userId, targetId)
        return ResponseEntity.ok().build()
    }

    @PostMapping("/friends/accept")
    fun acceptRequest(
        @AuthenticationPrincipal userId: UUID,
        @RequestParam requestId: UUID,
    ): ResponseEntity<Unit> {
        service.acceptRequest(userId, requestId)
        return ResponseEntity.ok().build()
    }

    @DeleteMapping("/friends")
    fun removeOrDecline(
        @AuthenticationPrincipal userId: UUID,
        @RequestParam targetId: UUID,
    ): ResponseEntity<Unit> {
        service.declineOrRemove(userId, targetId)
        return ResponseEntity.ok().build()
    }

    @GetMapping("/friends/suggestions")
    fun getSuggestions(@AuthenticationPrincipal userId: UUID): List<UserSearchResultDto> =
        service.getSuggestions(userId)

    @GetMapping("/users/search")
    fun searchUsers(
        @AuthenticationPrincipal userId: UUID,
        @RequestParam q: String,
    ): List<UserSearchResultDto> = service.searchUsers(q, userId)
}
