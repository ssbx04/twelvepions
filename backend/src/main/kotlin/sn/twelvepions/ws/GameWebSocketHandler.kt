package sn.twelvepions.ws

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.socket.CloseStatus
import org.springframework.web.socket.TextMessage
import org.springframework.web.socket.WebSocketSession
import org.springframework.web.socket.handler.TextWebSocketHandler
import sn.twelvepions.game.Color
import sn.twelvepions.game.GameException
import sn.twelvepions.game.GameService
import sn.twelvepions.game.MatchResult
import sn.twelvepions.game.MatchmakingService
import sn.twelvepions.game.Position
import sn.twelvepions.game.ai.dto.MoveDto
import sn.twelvepions.game.ai.dto.PositionDto
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import sn.twelvepions.auth.AuthService
import sn.twelvepions.config.FcmService
import sn.twelvepions.friends.FriendshipRepository
import sn.twelvepions.game.ai.Mariama
import sn.twelvepions.game.ai.FindBestMoveOptions
import kotlin.concurrent.thread
import java.util.UUID

/**
 * Handler principal du WebSocket. Reçoit les messages JSON, dispatche, broadcast.
 *
 * Messages entrants :
 *   { "type": "queue.join" }
 *   { "type": "queue.leave" }
 *   { "type": "game.move",          "gameId": "...", "sequence": [...] }
 *   { "type": "game.resign",        "gameId": "..." }
 *   { "type": "game.draw.offer",    "gameId": "..." }
 *   { "type": "game.draw.respond",  "gameId": "...", "accept": true|false }
 *   { "type": "game.oops.claim",    "gameId": "...", "position": {"r":N,"c":N} }
 *   { "type": "ping" }
 *
 * Messages sortants :
 *   { "type": "connected", "userId": "..." }
 *   { "type": "queue.queued" }
 *   { "type": "game.matched",       "state", "yourColor", "turnDeadlineEpochMs" }
 *   { "type": "game.resume",        "state", "yourColor", "turnDeadlineEpochMs" }
 *   { "type": "game.update",        "state", "lastMove", "turnDeadlineEpochMs", "oops"?, "oopsRemoved"? }
 *   { "type": "game.ended",         "state" }
 *   { "type": "game.draw.offered",  "gameId" }
 *   { "type": "game.draw.declined", "gameId", "offererId", "refusalsByOfferer", "max" }
 *   { "type": "opponent.disconnected", "gameId", "forfeitDeadlineEpochMs" }
 *   { "type": "opponent.reconnected",  "gameId" }
 *   { "type": "error", "code": "...", "message": "..." }
 *   { "type": "pong" }
 */
@Component
class GameWebSocketHandler(
    private val matchmaking: MatchmakingService,
    private val gameService: GameService,
    private val authService: AuthService,
    private val friendshipRepo: FriendshipRepository,
    private val registry: SessionRegistry,
    private val turnTimer: TurnTimer,
    private val reconnectGuard: ReconnectGuard,
    private val drawOffers: DrawOfferRegistry,
    private val oopsRegistry: OopsRegistry,
    private val challenges: ChallengeRegistry,
    private val fcm: FcmService,
    private val mapper: ObjectMapper,
) : TextWebSocketHandler() {
    private val log = LoggerFactory.getLogger(GameWebSocketHandler::class.java)

    override fun afterConnectionEstablished(session: WebSocketSession) {
        val userId = userIdOf(session) ?: return
        registry.register(userId, session)
        log.info("WS connected: user={} ({} online)", userId, registry.onlineCount)
        pushPresence(userId, "ONLINE")
        sendJson(session, mapOf("type" to "connected", "userId" to userId.toString()))

        // Défi en attente créé pendant que l'utilisateur était offline → le livrer maintenant.
        challenges.getPendingForTarget(userId)?.let { (challengeId, challenge) ->
            val challenger = runCatching { authService.getUser(challenge.challengerId) }.getOrNull()
            if (challenger != null) {
                sendJson(session, mapOf(
                    "type" to "game.challenge.received",
                    "challengeId" to challengeId.toString(),
                    "challengerId" to challenge.challengerId.toString(),
                    "challengerUsername" to (challenger.username ?: challenger.phone),
                    "challengerElo" to challenger.elo,
                ))
            }
        }

        // Si une partie est en cours, renvoyer son état au joueur qui revient
        // (et reprendre le turn timer suspendu par la déconnexion).
        val active = runCatching { gameService.findActiveGameOf(userId) }.getOrNull()
        if (active == null) {
            reconnectGuard.cancelDisconnect(userId)
            return
        }
        val gameId = UUID.fromString(active.state.gameId)
        val resumedDeadline = reconnectGuard.cancelDisconnect(userId, gameId)
        sendJson(
            session,
            mapOf(
                "type" to "game.resume",
                "yourColor" to active.yourColor.name,
                "state" to active.state,
                "turnDeadlineEpochMs" to (resumedDeadline ?: turnTimer.deadlineFor(gameId)),
            ),
        )
        // Notifier l'adversaire que je suis revenu.
        val opponentId = if (active.yourColor.name == "X") {
            UUID.fromString(active.state.playerO.id)
        } else {
            UUID.fromString(active.state.playerX.id)
        }
        registry.send(
            opponentId,
            mapper.writeValueAsString(
                mapOf("type" to "opponent.reconnected", "gameId" to gameId.toString()),
            ),
        )
    }

    override fun afterConnectionClosed(session: WebSocketSession, status: CloseStatus) {
        val userId = userIdOf(session) ?: return
        registry.unregister(userId, session)
        runCatching { matchmaking.leaveQueue(userId) }
        pushPresence(userId, "OFFLINE")
        // Annuler les défis envoyés par ce joueur → notifier les cibles
        challenges.cancelByChallenger(userId).forEach { (challengeId, targetId) ->
            registry.send(targetId, mapper.writeValueAsString(
                mapOf("type" to "game.challenge.cancelled", "challengeId" to challengeId.toString())
            ))
        }
        // Annuler les défis reçus par ce joueur → notifier les challengers
        challenges.cancelByTarget(userId).forEach { (challengeId, challengerId) ->
            registry.send(challengerId, mapper.writeValueAsString(
                mapOf("type" to "game.challenge.declined", "challengeId" to challengeId.toString())
            ))
        }
        log.info("WS closed: user={} status={} ({} online)", userId, status, registry.onlineCount)

        // Si le joueur était dans une partie active, lui la isser une fenêtre de reconnexion.
        val active = runCatching { gameService.findActiveGameOf(userId) }.getOrNull() ?: return
        val gameId = UUID.fromString(active.state.gameId)
        val deadline = reconnectGuard.armDisconnect(userId, gameId)
        val opponentId = if (active.yourColor.name == "X") {
            UUID.fromString(active.state.playerO.id)
        } else {
            UUID.fromString(active.state.playerX.id)
        }
        registry.send(
            opponentId,
            mapper.writeValueAsString(
                mapOf(
                    "type" to "opponent.disconnected",
                    "gameId" to gameId.toString(),
                    "forfeitDeadlineEpochMs" to deadline,
                ),
            ),
        )
    }

    override fun handleTextMessage(session: WebSocketSession, message: TextMessage) {
        val userId = userIdOf(session) ?: return
        try {
            val msg = mapper.readTree(message.payload)
            when (val type = msg["type"]?.asString()) {
                "queue.join" -> handleQueueJoin(userId, session)
                "queue.join.ai" -> handleQueueJoinAi(userId, session)
                "queue.leave" -> handleQueueLeave(userId, session)
                "game.move" -> handleMove(userId, msg)
                "game.resign" -> handleResign(userId, msg)
                "game.draw.offer" -> handleDrawOffer(userId, msg, session)
                "game.draw.respond" -> handleDrawRespond(userId, msg, session)
                "game.oops.claim"       -> handleOopsClaim(userId, msg, session)
                "game.challenge.send"   -> handleChallengeSend(userId, msg, session)
                "game.challenge.respond"-> handleChallengeRespond(userId, msg, session)
                "ping" -> sendJson(session, mapOf("type" to "pong"))
                else -> sendError(session, "unknown_type", "Type inconnu : $type")
            }
        } catch (e: GameException) {
            sendError(session, "game_error", e.message ?: "Erreur de jeu")
        } catch (e: Exception) {
            log.error("WS handler error", e)
            sendError(session, "internal_error", e.message ?: "Erreur serveur")
        }
    }

    // ─── Handlers ────────────────────────────────────────────────────────────

    private fun handleQueueJoin(userId: UUID, session: WebSocketSession) {
        when (val r = matchmaking.joinQueue(userId)) {
            is MatchResult.Queued ->
                sendJson(session, mapOf("type" to "queue.queued"))
            is MatchResult.Matched -> {
                val state = r.state
                val gameId = UUID.fromString(state.gameId)
                val deadline = turnTimer.arm(gameId)
                val msgX = mapOf(
                    "type" to "game.matched",
                    "yourColor" to "X",
                    "state" to state,
                    "turnDeadlineEpochMs" to deadline,
                )
                val msgO = mapOf(
                    "type" to "game.matched",
                    "yourColor" to "O",
                    "state" to state,
                    "turnDeadlineEpochMs" to deadline,
                )
                registry.send(r.playerXId, mapper.writeValueAsString(msgX))
                registry.send(r.playerOId, mapper.writeValueAsString(msgO))
            }
        }
    }

    private fun handleQueueJoinAi(userId: UUID, session: WebSocketSession) {
        val r = matchmaking.joinAiQueue(userId)
        val state = r.state
        val gameId = UUID.fromString(state.gameId)
        val deadline = turnTimer.arm(gameId)
        
        val msgUser = mapOf(
            "type" to "game.matched",
            "yourColor" to if (r.playerXId == userId) "X" else "O",
            "state" to state,
            "turnDeadlineEpochMs" to deadline,
        )
        registry.send(userId, mapper.writeValueAsString(msgUser))
        
        triggerAiIfNecessary(gameId)
    }

    private fun handleQueueLeave(userId: UUID, session: WebSocketSession) {
        matchmaking.leaveQueue(userId)
        sendJson(session, mapOf("type" to "queue.left"))
    }

    private fun handleMove(userId: UUID, msg: JsonNode) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val sequence = parseSequence(msg["sequence"])
        // Jouer son tour annule automatiquement toute fenêtre OOPS qu'on aurait pu réclamer.
        oopsRegistry.clear(gameId)
        val outcome = gameService.applyMove(gameId, userId, sequence)
        val state = outcome.state

        drawOffers.cancelPending(gameId)

        val finished = state.status == "FINISHED"
        val deadline = if (finished) {
            turnTimer.cancel(gameId)
            drawOffers.clearForGame(gameId)
            oopsRegistry.clear(gameId)
            null
        } else {
            turnTimer.arm(gameId)
        }

        // Si le coup était fautif, mémoriser pour que l'adversaire puisse réclamer surplace.
        val oopsBlock: Map<String, Any>? = if (!finished && outcome.faulty.isNotEmpty()) {
            val claimerColor = Color.valueOf(state.turn)
            oopsRegistry.set(gameId, claimerColor, outcome.faulty)
            mapOf(
                "claimableBy" to claimerColor.name,
                "faultyPositions" to outcome.faulty.map { mapOf("r" to it.r, "c" to it.c) },
            )
        } else null

        val (xId, oId) = gameService.playersOf(gameId)
        val update = mapOf(
            "type" to if (finished) "game.ended" else "game.update",
            "lastMove" to sequence,
            "state" to state,
            "turnDeadlineEpochMs" to deadline,
            "oops" to oopsBlock,
        )
        registry.broadcast(listOf(xId, oId), mapper.writeValueAsString(update))
        
        if (!finished) {
            triggerAiIfNecessary(gameId)
        }
    }

    private fun handleOopsClaim(userId: UUID, msg: JsonNode, session: WebSocketSession) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val pending = oopsRegistry.get(gameId) ?: run {
            sendError(session, "no_oops_pending", "Aucune sanction surplace en cours"); return
        }
        val (xId, oId) = gameService.playersOf(gameId)
        val claimerColor = when (userId) {
            xId -> Color.X
            oId -> Color.O
            else -> { sendError(session, "not_a_player", "Vous ne participez pas à cette partie"); return }
        }
        if (claimerColor != pending.claimerColor) {
            sendError(session, "not_your_oops", "Vous n'êtes pas le bénéficiaire de ce surplace"); return
        }
        val pos = msg["position"] ?: run {
            sendError(session, "bad_payload", "Champ 'position' manquant"); return
        }
        val target = Position(pos["r"].asInt(), pos["c"].asInt())
        if (target !in pending.faultyPositions) {
            sendError(session, "invalid_target", "Cette pièce n'est pas fautive"); return
        }

        doOopsClaim(userId, gameId, target)
    }

    private fun doOopsClaim(userId: UUID, gameId: UUID, target: Position) {
        val state = gameService.applyOopsRemoval(gameId, userId, target)
        oopsRegistry.clear(gameId)

        val finished = state.status == "FINISHED"
        val deadline = if (finished) {
            turnTimer.cancel(gameId)
            drawOffers.clearForGame(gameId)
            null
        } else {
            // Le retrait ne consomme pas le tour : on relance le timer du claimer.
            turnTimer.arm(gameId)
        }

        val (xId, oId) = gameService.playersOf(gameId)
        val payload = mapper.writeValueAsString(
            mapOf(
                "type" to if (finished) "game.ended" else "game.update",
                "state" to state,
                "turnDeadlineEpochMs" to deadline,
                "oopsRemoved" to mapOf("r" to target.r, "c" to target.c),
            ),
        )
        registry.broadcast(listOf(xId, oId), payload)
    }

    private fun handleResign(userId: UUID, msg: JsonNode) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val state = gameService.resign(gameId, userId)
        turnTimer.cancel(gameId)
        drawOffers.clearForGame(gameId)
        val (xId, oId) = gameService.playersOf(gameId)
        val payload = mapper.writeValueAsString(mapOf("type" to "game.ended", "state" to state))
        registry.broadcast(listOf(xId, oId), payload)
    }

    private fun handleDrawOffer(userId: UUID, msg: JsonNode, session: WebSocketSession) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val (xId, oId) = gameService.playersOf(gameId)
        if (userId != xId && userId != oId) {
            sendError(session, "not_a_player", "Vous ne participez pas à cette partie")
            return
        }
        if (!drawOffers.offer(gameId, userId)) {
            sendError(session, "draw_pending", "Une demande de nulle est déjà en cours")
            return
        }
        val opponentId = if (userId == xId) oId else xId
        
        // Si l'adversaire est l'IA, elle accepte la nulle
        if (opponentId.toString() == "00000000-0000-0000-0000-000000000000") {
            drawOffers.consumeAccept(gameId)
            val state = gameService.acceptDraw(gameId)
            turnTimer.cancel(gameId)
            drawOffers.clearForGame(gameId)
            val payload = mapper.writeValueAsString(
                mapOf("type" to "game.ended", "state" to state),
            )
            registry.broadcast(listOf(xId, oId), payload)
            return
        }
        
        registry.send(
            opponentId,
            mapper.writeValueAsString(
                mapOf("type" to "game.draw.offered", "gameId" to gameId.toString()),
            ),
        )
    }

    private fun handleDrawRespond(userId: UUID, msg: JsonNode, session: WebSocketSession) {
        val gameId = UUID.fromString(msg["gameId"].asString())
        val accept = msg["accept"]?.asBoolean() ?: run {
            sendError(session, "bad_payload", "Champ 'accept' manquant"); return
        }
        val pendingOfferer = drawOffers.pendingOffererOf(gameId) ?: run {
            sendError(session, "no_draw_pending", "Aucune demande de nulle en cours"); return
        }
        if (userId == pendingOfferer) {
            sendError(session, "cannot_respond_own", "Vous ne pouvez pas répondre à votre propre demande")
            return
        }
        val (xId, oId) = gameService.playersOf(gameId)

        if (accept) {
            drawOffers.consumeAccept(gameId)
            val state = gameService.acceptDraw(gameId)
            turnTimer.cancel(gameId)
            drawOffers.clearForGame(gameId)
            val payload = mapper.writeValueAsString(
                mapOf("type" to "game.ended", "state" to state),
            )
            registry.broadcast(listOf(xId, oId), payload)
            return
        }

        val result = drawOffers.consumeDecline(gameId) ?: return
        val payload = mapper.writeValueAsString(
            mapOf(
                "type" to "game.draw.declined",
                "gameId" to gameId.toString(),
                "offererId" to result.offererId.toString(),
                "refusalsByOfferer" to result.refusals,
                "max" to DrawOfferRegistry.MAX_REFUSALS,
            ),
        )
        registry.broadcast(listOf(xId, oId), payload)

        // Au 3e refus, l'offreur perd par forfait.
        if (result.refusals >= DrawOfferRegistry.MAX_REFUSALS) {
            val state = gameService.resign(gameId, result.offererId)
            turnTimer.cancel(gameId)
            drawOffers.clearForGame(gameId)
            val ended = mapper.writeValueAsString(mapOf("type" to "game.ended", "state" to state))
            registry.broadcast(listOf(xId, oId), ended)
        }
    }

    private fun handleChallengeSend(userId: UUID, msg: JsonNode, session: WebSocketSession) {
        val targetId = runCatching { UUID.fromString(msg["targetId"].asString()) }.getOrNull()
            ?: run { sendError(session, "bad_payload", "targetId manquant ou invalide"); return }

        if (targetId == userId) { sendError(session, "bad_challenge", "Impossible de se défier soi-même"); return }
        if (targetId == UUID(0, 0)) { sendError(session, "bad_challenge", "Impossible de défier Mariama directement"); return }
        if (gameService.findActiveGameOf(targetId) != null) { sendError(session, "target_in_game", "Ce joueur est déjà en partie"); return }
        if (gameService.findActiveGameOf(userId) != null) { sendError(session, "already_in_game", "Tu es déjà en partie"); return }

        val challenger = authService.getUser(userId)
        val challengeId = UUID.randomUUID()
        val targetOnline = registry.get(targetId) != null

        challenges.create(challengeId, userId, targetId) { expiredId ->
            registry.send(userId, mapper.writeValueAsString(
                mapOf("type" to "game.challenge.expired", "challengeId" to expiredId.toString())
            ))
            registry.send(targetId, mapper.writeValueAsString(
                mapOf("type" to "game.challenge.cancelled", "challengeId" to expiredId.toString())
            ))
        }

        if (targetOnline) {
            registry.send(targetId, mapper.writeValueAsString(mapOf(
                "type" to "game.challenge.received",
                "challengeId" to challengeId.toString(),
                "challengerId" to userId.toString(),
                "challengerUsername" to (challenger.username ?: challenger.phone),
                "challengerElo" to challenger.elo,
            )))
        } else {
            fcm.sendToUser(targetId, "12 Pions",
                "${challenger.username ?: "Un joueur"} vous défie ! Ouvrez l'app pour accepter.",
                mapOf("type" to "challenge_received", "challengeId" to challengeId.toString(),
                      "challengerId" to userId.toString()))
        }
        sendJson(session, mapOf("type" to "game.challenge.sent", "challengeId" to challengeId.toString()))
    }

    private fun handleChallengeRespond(userId: UUID, msg: JsonNode, session: WebSocketSession) {
        val challengeId = runCatching { UUID.fromString(msg["challengeId"].asString()) }.getOrNull()
            ?: run { sendError(session, "bad_payload", "challengeId manquant"); return }
        val accept = msg["accept"]?.asBoolean()
            ?: run { sendError(session, "bad_payload", "accept manquant"); return }

        val challenge = challenges.consume(challengeId)
            ?: run { sendError(session, "challenge_expired", "Ce défi a expiré ou n'existe plus"); return }

        if (challenge.targetId != userId) {
            sendError(session, "not_your_challenge", "Ce défi ne vous est pas destiné"); return
        }

        if (!accept) {
            registry.send(challenge.challengerId, mapper.writeValueAsString(
                mapOf("type" to "game.challenge.declined", "challengeId" to challengeId.toString())
            ))
            return
        }

        // Accepté → créer la partie (challengerId = X, target = O)
        val state = gameService.createGame(challenge.challengerId, userId)
        val gameId = UUID.fromString(state.gameId)
        val deadline = turnTimer.arm(gameId)
        registry.send(challenge.challengerId, mapper.writeValueAsString(mapOf(
            "type" to "game.matched", "yourColor" to "X", "state" to state, "turnDeadlineEpochMs" to deadline,
        )))
        registry.send(userId, mapper.writeValueAsString(mapOf(
            "type" to "game.matched", "yourColor" to "O", "state" to state, "turnDeadlineEpochMs" to deadline,
        )))
    }

    private fun pushPresence(userId: UUID, presence: String) {
        val friendIds = runCatching {
            friendshipRepo.findAcceptedFriendsOf(userId).map { f ->
                if (f.requesterId == userId) f.addresseeId else f.requesterId
            }
        }.getOrDefault(emptyList())
        val payload = mapper.writeValueAsString(mapOf(
            "type" to "friend.presence.changed",
            "userId" to userId.toString(),
            "presence" to presence,
        ))
        friendIds.forEach { registry.send(it, payload) }
    }

    private fun triggerAiIfNecessary(gameId: UUID) {
        val state = try {
            gameService.getState(gameId)
        } catch (e: Exception) {
            return
        }
        
        if (state.status != "IN_PROGRESS") return
        
        val isAiTurn = (state.turn == "X" && state.playerX.id == "00000000-0000-0000-0000-000000000000") || 
                       (state.turn == "O" && state.playerO.id == "00000000-0000-0000-0000-000000000000")
                       
        if (!isAiTurn) return
        
        val aiId = UUID.fromString("00000000-0000-0000-0000-000000000000")
        
        thread(start = true) {
            try {
                // Délai avant de jouer : laisse le client voir l'état fautif
                Thread.sleep(1500)

                val color = sn.twelvepions.game.Color.valueOf(state.turn)

                // Mariama réclame le surplace si disponible
                val pendingOops = oopsRegistry.get(gameId)
                if (pendingOops != null && pendingOops.claimerColor == color) {
                    val target = pendingOops.faultyPositions.first()
                    doOopsClaim(aiId, gameId, target)
                    // Laisser le client terminer la démo surplace (≈1400ms) + marge
                    Thread.sleep(2000)
                }
                
                // Récupération de l'état frais juste avant de jouer (après éventuel oops)
                val freshState = gameService.getState(gameId)
                if (freshState.status != "IN_PROGRESS" || freshState.turn != state.turn) return@thread
                
                val board = sn.twelvepions.game.Board.parse(freshState.board)
                
                // Profondeur = 4 (Niveau intermédiaire/difficile)
                val result = Mariama.findBestMove(board, color, FindBestMoveOptions(maxDepth = 4))
                
                val sequence = result.turn?.sequence?.map { m: sn.twelvepions.game.Move ->
                    sn.twelvepions.game.ai.dto.MoveDto(
                        from = sn.twelvepions.game.ai.dto.PositionDto(m.from.r, m.from.c),
                        to = sn.twelvepions.game.ai.dto.PositionDto(m.to.r, m.to.c),
                        captured = m.captured?.let { sn.twelvepions.game.ai.dto.PositionDto(it.r, it.c) },
                    )
                } ?: emptyList()
                
                if (sequence.isNotEmpty()) {
                    val msg = mapper.createObjectNode()
                    msg.put("gameId", gameId.toString())
                    msg.set("sequence", mapper.valueToTree(sequence))
                    
                    // On réutilise handleMove qui gère déjà le broadcast et les timers
                    handleMove(aiId, msg)
                } else {
                    // L'IA n'a pas de coup valide -> elle abandonne ou passe
                    val msgResign = mapper.createObjectNode()
                    msgResign.put("gameId", gameId.toString())
                    handleResign(aiId, msgResign)
                }
            } catch (e: Exception) {
                log.error("Erreur IA sur partie \$gameId", e)
            }
        }
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private fun userIdOf(session: WebSocketSession): UUID? =
        session.attributes["userId"] as? UUID

    private fun sendJson(session: WebSocketSession, body: Any) {
        if (!session.isOpen) return
        synchronized(session) { session.sendMessage(TextMessage(mapper.writeValueAsString(body))) }
    }

    private fun sendError(session: WebSocketSession, code: String, message: String) {
        sendJson(session, mapOf("type" to "error", "code" to code, "message" to message))
    }

    private fun parseSequence(node: JsonNode?): List<MoveDto> {
        require(node != null && node.isArray) { "sequence must be an array" }
        val out = mutableListOf<MoveDto>()
        for (m in node) {
            val captured = m["captured"]
            out += MoveDto(
                from = PositionDto(m["from"]["r"].asInt(), m["from"]["c"].asInt()),
                to = PositionDto(m["to"]["r"].asInt(), m["to"]["c"].asInt()),
                captured = if (captured == null || captured.isNull) null
                    else PositionDto(captured["r"].asInt(), captured["c"].asInt()),
            )
        }
        return out
    }
}
