package sn.twelvepions

import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Test
import org.springframework.boot.test.context.SpringBootTest

@SpringBootTest
@Disabled("Nécessite Postgres + Redis. À activer avec Testcontainers plus tard.")
class BackendApplicationTests {

	@Test
	fun contextLoads() {
	}

}
