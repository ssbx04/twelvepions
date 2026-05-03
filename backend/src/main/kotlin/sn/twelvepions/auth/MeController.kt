package sn.twelvepions.auth

import org.springframework.security.core.annotation.AuthenticationPrincipal
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import sn.twelvepions.auth.dto.UserDto
import java.util.UUID

@RestController
@RequestMapping("/me")
class MeController(
    private val authService: AuthService,
) {
    @GetMapping
    fun me(@AuthenticationPrincipal userId: UUID): UserDto = authService.getUser(userId)
}
