import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../blocs/game/game_bloc.dart';
import '../widgets/game_banner_widget.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/disconnect_overlay.dart';
import '../widgets/pion_widget.dart';
import '../widgets/turn_timer_widget.dart';

class GamePage extends StatelessWidget {
  final String gameId;
  final String yourColor;
  final Map<String, dynamic>? initialStateData;

  const GamePage({
    super.key,
    required this.gameId,
    required this.yourColor,
    this.initialStateData,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GameBloc>(
      create: (_) => sl<GameBloc>()..add(GameStarted(gameId: gameId, yourColor: yourColor, initialStateData: initialStateData)),
      child: Scaffold(
        body: AppBackground(
          greenOffset: const Offset(200, -100),
          redOffset: const Offset(-200, 300),
          child: SafeArea(
            child: const _GameView(),
          ),
        ),
      ),
    );
  }
}

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  BannerType? _activeBanner;
  bool _showEndOverlay = false;
  GameEndResult? _endResult;
  List<String>? _prevBoard;
  bool _endSoundPlayed = false;
  bool _prevSurplace = false;

  void _showBanner(BannerType type) {
    setState(() => _activeBanner = type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GameBloc, GameState>(
      listener: (context, state) {
        if (state is GameError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.red),
          );
        } else if (state is GameActive) {
          // Detect coudou banner (minimum 2 captures dans la chaîne)
          if (state.pendingSequence.length >= 2 && _prevBoard != null && _prevBoard != state.board) {
            _showBanner(BannerType.coudou);
            SoundService.instance.play(SoundType.coudou);
          }
          // Detect oops success (claimer via surplaceMode toggle, ou les deux via oopsJustHappened)
          if (state.oopsJustHappened || (_prevSurplace && !state.surplaceMode && _prevBoard != null && _prevBoard != state.board)) {
            _showBanner(BannerType.oops);
            SoundService.instance.play(SoundType.oops);
          }
          _prevBoard = state.board;
          _prevSurplace = state.surplaceMode;

          // Detect end of game
          if (state.isFinished && !_showEndOverlay) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              final isWinner = state.winner == state.yourColor;
              final isDraw = state.winner == null;
              setState(() {
                _showEndOverlay = true;
                _endResult = isDraw
                    ? GameEndResult.draw
                    : isWinner
                        ? GameEndResult.victory
                        : GameEndResult.defeat;
              });
              if (!_endSoundPlayed) {
                _endSoundPlayed = true;
                if (!isDraw) {
                  SoundService.instance.play(isWinner ? SoundType.win : SoundType.fail);
                }
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state is GameInitial || state is GameLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
        }

        if (state is GameActive) {
          return Stack(
            children: [
              _buildGameContent(context, state),
              // Banners
              if (_activeBanner != null)
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: GameBannerWidget(
                      key: ValueKey('banner_${DateTime.now().millisecondsSinceEpoch}'),
                      type: _activeBanner!,
                      onDismissed: () => setState(() => _activeBanner = null),
                    ),
                  ),
                ),
              // Disconnect overlay (bloquant)
              if (state.isOpponentDisconnected && state.forfeitDeadlineEpochMs != null)
                DisconnectOverlay(forfeitDeadlineEpochMs: state.forfeitDeadlineEpochMs!),
              // End overlay
              if (_showEndOverlay && _endResult != null)
                Positioned.fill(
                  child: Builder(builder: (_) {
                    String? winnerLabel;
                    Color? winnerColor;
                    if (state.winner != null) {
                      winnerLabel = state.winner == 'X' ? 'Vert' : 'Rouge';
                      winnerColor = state.winner == 'X' ? AppColors.green : AppColors.red;
                    }
                    return GameEndOverlay(
                      result: _endResult!,
                      winnerLabel: winnerLabel,
                      winnerColor: winnerColor,
                      onReplay: () {
                        setState(() => _showEndOverlay = false);
                        context.goNamed('matchmaking');
                      },
                      onQuit: () {
                        setState(() => _showEndOverlay = false);
                        context.go('/home');
                      },
                    );
                  }),
                ),
            ],
          );
        }

        return const Center(child: Text('Erreur d\'état', style: TextStyle(color: Colors.red)));
      },
    );
  }

  Widget _buildGameContent(BuildContext context, GameActive state) {
    final opponentColor = state.yourColor == 'X' ? 'O' : 'X';
    final myPlayer = state.yourColor == 'X' ? state.playerX : state.playerO;
    final oppPlayer = opponentColor == 'X' ? state.playerX : state.playerO;
    
    final int totalPiecesPerPlayer = 12;
    final myCount = _countPieces(state.board, state.yourColor);
    final oppCount = _countPieces(state.board, opponentColor);
    final myCapturedPieces = totalPiecesPerPlayer - myCount;
    final oppCapturedPieces = totalPiecesPerPlayer - oppCount;

    return Column(
      children: [
        // ─── Header : Durée du match + Mute ─────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _MatchDurationWidget(isFinished: state.isFinished),
                Positioned(
                  right: 0,
                  child: _MuteButton(),
                ),
              ],
            ),
          ),
        ),

        // ─── Joueurs et Timer ──────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _PlayerAvatar(
                username: oppPlayer['username'] as String,
                elo: oppPlayer['elo'] as int,
                color: opponentColor,
                isActive: state.turn == opponentColor,
              ),
              Expanded(
                child: Center(
                  child: state.localMustContinueFrom != null && state.coudouDeadlineEpochMs != null
                      ? TurnTimerWidget(
                          deadlineEpochMs: state.coudouDeadlineEpochMs,
                          maxDurationSeconds: 3,
                        )
                      : TurnTimerWidget(deadlineEpochMs: state.turnDeadlineEpochMs),
                ),
              ),
              _PlayerAvatar(
                username: myPlayer['username'] as String,
                elo: myPlayer['elo'] as int,
                color: state.yourColor,
                isActive: state.turn == state.yourColor,
              ),
            ],
          ),
        ),

        const Spacer(),

        _buildPiecesBar(opponentColor, oppCount, oppCapturedPieces),

        // ─── Plateau ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GameBoardWidget(
            board: state.board,
            yourColor: state.yourColor,
            isMyTurn: state.isMyTurn,
            selectedCell: state.selectedCell,
            validDestinations: state.validDestinations,
            surplaceMode: state.surplaceMode,
            oopsFaultyPositions: state.oopsFaultyPositions,
            chainFromCell: state.localMustContinueFrom,
            onCellClicked: (r, c) {
              if (state.surplaceMode) {
                context.read<GameBloc>().add(GameSurplaceClicked(r, c));
              } else {
                context.read<GameBloc>().add(GameCellClicked(r, c));
              }
            },
          ),
        ),

        _buildPiecesBar(state.yourColor, myCount, myCapturedPieces),

        const Spacer(),

        // ─── Actions ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: state.surplaceMode ? 'touch_app' : 'Surplace',
                useMaterialIcon: state.surplaceMode,
                materialIcon: Icons.touch_app_rounded,
                label: state.surplaceMode ? 'Annuler' : 'Surplace',
                onTap: state.isFinished
                    ? null
                    : state.surplaceMode
                        ? () => context.read<GameBloc>().add(GameSurplaceCancelled())
                        : () => context.read<GameBloc>().add(GameSurplaceRequested()),
              ),
              _ActionButton(
                icon: 'MatchNul',
                label: 'Match nul',
                onTap: state.isFinished ? null : () => context.read<GameBloc>().add(GameDrawOffered()),
              ),
              _ActionButton(
                icon: 'NouvellePartie',
                label: state.isFinished ? 'Nouvelle partie' : 'Abandonner',
                onTap: () {
                  if (state.isFinished) {
                    context.goNamed('matchmaking');
                  } else {
                    context.read<GameBloc>().add(GameResigned());
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _countPieces(List<String> board, String color) {
    int count = 0;
    for (var row in board) {
      for (var i = 0; i < row.length; i++) {
        if (row[i].toUpperCase() == color) count++;
      }
    }
    return count;
  }

  Widget _buildPiecesBar(String color, int remaining, int captured) {
    final pieceColor = color == 'X' ? AppColors.green : AppColors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$remaining',
            style: TextStyle(color: pieceColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 6),
          ...List.generate(
            captured,
            (index) => Padding(
              padding: const EdgeInsets.only(right: 3.0),
              child: Opacity(
                opacity: 0.4,
                child: PionWidget(type: color, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  final String username;
  final int elo;
  final String color;
  final bool isActive;

  const _PlayerAvatar({
    required this.username,
    required this.elo,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = color == 'X' ? AppColors.green : AppColors.red;
    
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
            border: Border.all(
              color: isActive ? AppColors.yellow : avatarColor,
              width: 3,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.yellow.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Center(
            child: Text(
              username.substring(0, 2).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          username,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(
          '$elo Elo',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback? onTap;
  final bool isHighlighted;
  final bool useMaterialIcon;
  final IconData? materialIcon;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
    this.useMaterialIcon = false,
    this.materialIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? AppColors.red.withValues(alpha: 0.3)
                    : AppColors.yellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: isHighlighted
                    ? Border.all(color: AppColors.red, width: 2)
                    : null,
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: AppColors.red.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: useMaterialIcon && materialIcon != null
                  ? Icon(
                      materialIcon,
                      size: 24,
                      color: isHighlighted ? AppColors.red : AppColors.yellow,
                    )
                  : SvgPicture.asset(
                      'assets/icons/$icon.svg',
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        isHighlighted ? AppColors.red : AppColors.yellow,
                        BlendMode.srcIn,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isHighlighted ? AppColors.red : AppColors.yellow,
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDurationWidget extends StatefulWidget {
  final bool isFinished;
  const _MatchDurationWidget({this.isFinished = false});

  @override
  State<_MatchDurationWidget> createState() => _MatchDurationWidgetState();
}

class _MatchDurationWidgetState extends State<_MatchDurationWidget> {
  late final DateTime _startTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant _MatchDurationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFinished && !oldWidget.isFinished) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_startTime);
    final hours = elapsed.inHours.toString().padLeft(2, '0');
    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.yellow.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.yellow.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            color: AppColors.yellow,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$hours:$minutes:$seconds',
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuteButton extends StatefulWidget {
  @override
  State<_MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<_MuteButton> {
  @override
  Widget build(BuildContext context) {
    final muted = SoundService.instance.isMuted;
    return GestureDetector(
      onTap: () async {
        await SoundService.instance.toggleMute();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.yellow.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: AppColors.yellow,
          size: 20,
        ),
      ),
    );
  }
}
