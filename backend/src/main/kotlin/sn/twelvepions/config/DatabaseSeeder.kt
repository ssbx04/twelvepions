package sn.twelvepions.config

import org.springframework.boot.CommandLineRunner
import org.springframework.stereotype.Component
import sn.twelvepions.auth.User
import sn.twelvepions.auth.UserRepository
import sn.twelvepions.auth.UserLevel
import java.util.UUID

@Component
class DatabaseSeeder(
    private val users: UserRepository
) : CommandLineRunner {

    companion object {
        val MARIAMA_ID: UUID = UUID.fromString("00000000-0000-0000-0000-000000000000")
    }

    override fun run(vararg args: String) {
        if (!users.existsById(MARIAMA_ID)) {
            val mariama = User(
                id = MARIAMA_ID,
                phone = "000000000",
                fullName = "Mariama",
                username = "Mariama (IA)",
                level = UserLevel.EXPERT,
                elo = 1500
            )
            users.save(mariama)
        }
    }
}
