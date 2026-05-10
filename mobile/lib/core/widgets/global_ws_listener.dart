import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../di/service_locator.dart';
import '../router/app_router.dart';
import '../services/websocket_service.dart';

/// Un widget global qui englobe le routeur de l'application.
/// Il écoute les messages WebSocket vitaux comme "game.resume".
/// Si le serveur nous dit qu'une partie est en cours, il nous
/// redirige automatiquement vers l'échiquier.
class GlobalWsListener extends StatefulWidget {
  final Widget child;

  const GlobalWsListener({super.key, required this.child});

  @override
  State<GlobalWsListener> createState() => _GlobalWsListenerState();
}

class _GlobalWsListenerState extends State<GlobalWsListener> {
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _wsSubscription = sl<WebSocketService>().messages.listen((message) {
      switch (message['type'] as String?) {
        case 'game.resume':
          _handleGameResume(message);
        case 'game.challenge.received':
          _handleChallengeReceived(message);
        case 'game.challenge.declined':
        case 'game.challenge.expired':
          _handleChallengeDeclinedOrExpired(message);
        case 'game.matched':
          _handleGameMatched(message);
        case 'friend.request.received':
          _showSnackbar('${message['fromUsername']} vous a envoyé une demande d\'ami', AppColors.green);
        case 'friend.request.accepted':
          _showSnackbar('${message['byUsername']} a accepté votre demande d\'ami', AppColors.green);
        case 'error':
          final code = message['code'] as String? ?? '';
          final errorMsg = switch (code) {
            'target_offline'  => 'Ce joueur est hors ligne',
            'target_in_game'  => 'Ce joueur est déjà en partie',
            'already_in_game' => 'Tu es déjà en partie',
            'challenge_expired' => 'Ce défi a expiré',
            _ => null,
          };
          if (errorMsg != null) _showSnackbar(errorMsg, AppColors.red);
      }
    });
  }

  void _handleGameResume(Map<String, dynamic> message) {
    final ctx = _navContext;
    if (ctx == null) return;
    // Évite de push la page si on est DÉJÀ sur la page de ce jeu
    final router = GoRouter.of(ctx);
    final currentRoute = router.routerDelegate.currentConfiguration.uri.path;
    
    final stateData = message['state'] as Map<String, dynamic>;
    final gameId = stateData['gameId'] as String;

    if (currentRoute == '/game/$gameId') {
      return; // On est déjà au bon endroit, le GameBloc gérera la synchro
    }

    // Sinon, on force la navigation vers la page de jeu
    // Note: on utilise 'push' ou 'go'. pushReplacementNamed est idéal.
    router.pushReplacementNamed(
      'game',
      pathParameters: {'gameId': gameId},
      extra: {
        'yourColor': message['yourColor'],
        'stateData': stateData,
      },
    );
  }

  BuildContext? get _navContext => rootNavigatorKey.currentContext;

  void _showSnackbar(String text, Color color) {
    final ctx = _navContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: color,
      duration: const Duration(seconds: 4),
    ));
  }

  void _handleGameMatched(Map<String, dynamic> message) {
    final ctx = _navContext;
    if (ctx == null) return;

    final currentPath = GoRouter.of(ctx).routerDelegate.currentConfiguration.uri.path;
    // La page matchmaking gère elle-même la navigation via MatchmakingBloc
    if (currentPath == '/matchmaking') return;

    ScaffoldMessenger.of(ctx).hideCurrentSnackBar();

    final stateData = message['state'] as Map<String, dynamic>;
    final gameId = stateData['gameId'] as String;
    final yourColor = message['yourColor'] as String;

    GoRouter.of(ctx).pushReplacementNamed(
      'game',
      pathParameters: {'gameId': gameId},
      extra: {'yourColor': yourColor, 'stateData': stateData},
    );
  }

  void _handleChallengeReceived(Map<String, dynamic> message) {
    final ctx = _navContext;
    if (ctx == null) return;
    final challengeId = message['challengeId'] as String;
    final username = message['challengerUsername'] as String;
    final elo = message['challengerElo'] as int;

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => _ChallengeDialog(
        challengeId: challengeId,
        challengerUsername: username,
        challengerElo: elo,
        wsService: sl<WebSocketService>(),
      ),
    );
  }

  void _handleChallengeDeclinedOrExpired(Map<String, dynamic> message) {
    final ctx = _navContext;
    if (ctx == null) return;
    final type = message['type'] as String;
    final label = type == 'game.challenge.declined' ? 'a refusé votre défi' : 'n\'a pas répondu';
    ScaffoldMessenger.of(ctx)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Votre adversaire $label.'),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ));
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ─── Dialog défi entrant ──────────────────────────────────────────────────────

class _ChallengeDialog extends StatefulWidget {
  final String challengeId;
  final String challengerUsername;
  final int challengerElo;
  final WebSocketService wsService;

  const _ChallengeDialog({
    required this.challengeId,
    required this.challengerUsername,
    required this.challengerElo,
    required this.wsService,
  });

  @override
  State<_ChallengeDialog> createState() => _ChallengeDialogState();
}

class _ChallengeDialogState extends State<_ChallengeDialog> {
  late int _secondsLeft;
  Timer? _timer;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _secondsLeft = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _dismiss();
    });
    // Fermer le dialog si le challenger annule / déconnecte
    _wsSub = widget.wsService.messages.listen((msg) {
      if ((msg['type'] == 'game.challenge.cancelled') &&
          msg['challengeId'] == widget.challengeId) {
        _dismiss();
      }
    });
  }

  void _respond(bool accept) {
    widget.wsService.sendMessage({
      'type': 'game.challenge.respond',
      'challengeId': widget.challengeId,
      'accept': accept,
    });
    _dismiss();
  }

  void _dismiss() {
    _timer?.cancel();
    _wsSub?.cancel();
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E110A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  widget.challengerUsername.substring(0, widget.challengerUsername.length.clamp(0, 2)).toUpperCase(),
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Défi reçu !', style: AppTextStyles.h2.copyWith(color: AppColors.yellow, fontSize: 18)),
            const SizedBox(height: 6),
            Text(
              '${widget.challengerUsername} vous défie',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('ELO ${widget.challengerElo}', style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
            const SizedBox(height: 20),
            // Compte à rebours
            Text(
              '$_secondsLeft s',
              style: TextStyle(
                color: _secondsLeft <= 10 ? AppColors.red : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _respond(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respond(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
