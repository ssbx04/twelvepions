package sn.twelvepions

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.time.Instant

@RestController
class HealthController {

    @GetMapping("/health")
    fun health(): Map<String, Any> = mapOf(
        "status" to "ok",
        "service" to "12pions-backend",
        "timestamp" to Instant.now().toString(),
    )
}
