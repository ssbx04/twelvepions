package sn.twelvepions.config

import com.google.auth.oauth2.GoogleCredentials
import com.google.firebase.FirebaseApp
import com.google.firebase.FirebaseOptions
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.Message
import com.google.firebase.messaging.Notification
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import sn.twelvepions.auth.UserRepository
import java.util.Base64
import java.util.UUID

@Service
class FcmService(private val users: UserRepository) {

    private val log = LoggerFactory.getLogger(FcmService::class.java)
    private val enabled: Boolean

    init {
        val raw = System.getenv("FIREBASE_CREDENTIALS_JSON")
        enabled = if (!raw.isNullOrBlank()) {
            runCatching {
                // Accepte JSON brut ou JSON encodé en base64.
                // getMimeDecoder tolère les sauts de ligne dans la valeur base64.
                val json = runCatching { Base64.getMimeDecoder().decode(raw).toString(Charsets.UTF_8) }
                    .getOrDefault(raw)
                val credentials = GoogleCredentials.fromStream(json.byteInputStream())
                val options = FirebaseOptions.builder().setCredentials(credentials).build()
                if (FirebaseApp.getApps().isEmpty()) FirebaseApp.initializeApp(options)
                log.info("Firebase Admin SDK initialisé")
            }.onFailure { log.warn("Échec init Firebase : {}", it.message) }.isSuccess
        } else {
            log.info("FIREBASE_CREDENTIALS_JSON absent — notifications FCM désactivées")
            false
        }
    }

    fun sendToUser(userId: UUID, title: String, body: String, data: Map<String, String> = emptyMap()) {
        if (!enabled) return
        val token = users.findById(userId).orElse(null)?.fcmToken ?: return
        sendToToken(token, title, body, data)
    }

    fun sendToToken(token: String, title: String, body: String, data: Map<String, String> = emptyMap()) {
        if (!enabled || token.isBlank()) return
        runCatching {
            val message = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .putAllData(data)
                .build()
            FirebaseMessaging.getInstance().send(message)
        }.onFailure { log.warn("FCM send failed: {}", it.message) }
    }
}
