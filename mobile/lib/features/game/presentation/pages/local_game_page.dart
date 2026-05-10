import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/widgets/app_background.dart';
import '../blocs/local_game/local_game_bloc.dart';
import '../widgets/game_banner_widget.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/game_end_overlay.dart';
import '../widgets/pion_widget.dart';
import '../widgets/turn_timer_widget.dart';

class LocalGamePage extends StatelessWidget {
  const LocalGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocalGameBloc>(
      create: (_) => LocalGameBloc(),
      child: Scaffold(
        body: AppBackground(
          greenOffset: const Offset(200, -100),
          redOffset: const Offset(-200, 300),
          child: SafeArea(
            child: const _LocalGameView(),
          ),
        ),
      ),
    );
  }
}

class _LocalGameView extends StatefulWidget {
  const _LocalGameView();

  @override
  State<_LocalGameView> createState() => _LocalGameViewState();
}

class _LocalGameViewState extends State<_LocalGameView> {
  BannerType? _activeBanner;
  bool _showEndOverlay = false;
  GameEndResult? _endResult;
  List<String>? _prevBoard;
  bool _endSoundPlayed = false;

  bool _prevSurplace = false;
  String? _winner;

  void _showBanner(BannerType type) {
    setState(() => _activeBanner = type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LocalGameBloc, LocalGameState>(
      listener: (context, state) {
        if (state is LocalGameActive) {
          // Detect coudou (minimum 2 captures dans la chaîne)
          if (state.chainCaptureCount >= 2 && _prevBoard != null && _prevBoard != state.board) {
            _showBanner(BannerType.coudou);
            SoundService.instance.play(SoundType.coudou);
          }
          // Detect oops success
          if (_prevSurplace && !state.surplaceMode && _prevBoard != null && _prevBoard != state.board) {
            _showBanner(BannerType.oops);
            SoundService.instance.play(SoundType.oops);
          }
          _prevBoard = state.board;
          _prevSurplace = state.surplaceMode;

          if (state.isFinished && !_showEndOverlay) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (!mounted) return;
              final isDraw = state.winner == null;
              setState(() {
                _showEndOverlay = true;
                _winner = state.winner;
                _endResult = isDraw ? GameEndResult.draw : GameEndResult.victory;
              });
              if (!_endSoundPlayed) {
                _endSoundPlayed = true;
                if (!isDraw) {
                  SoundService.instance.play(SoundType.win);
                }
              }
            });
          }
        }
      },
      builder: (context, state) {
        if (state is! LocalGameActive) {
          return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
        }

        return Stack(
          children: [
            _buildGameContent(context, state),
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
            if (_showEndOverlay && _endResult != null)
              Positioned.fill(
                child: GameEndOverlay(
                  result: _endResult!,
                  winnerLabel: _winner != null ? (_winner == 'X' ? 'Vert' : 'Rouge') : null,
                  winnerColor: _winner != null ? (_winner == 'X' ? AppColors.green : AppColors.red) : null,
                  onReplay: () {
                    setState(() {
                      _showEndOverlay = false;
                      _endSoundPlayed = false;
                      _winner = null;
                    });
                    context.read<LocalGameBloc>().add(LocalNewGame());
                  },
                  onQuit: () {
                    setState(() => _showEndOverlay = false);
                    context.pop();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGameContent(BuildContext context, LocalGameActive s) {
    final int totalPiecesPerPlayer = 12;
    final xCount = _countPieces(s.board, 'X');
    final oCount = _countPieces(s.board, 'O');
    final xCaptured = totalPiecesPerPlayer - xCount;
    final oCaptured = totalPiecesPerPlayer - oCount;
    final viewColor = 'O';

    return Column(
      children: [
        // ─── Header + Mute ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Builder(builder: (_) {
                  final displayColor = s.isFinished && s.winner != null
                      ? s.winner!
                      : s.turn;
                  final color = displayColor == 'X' ? AppColors.green : AppColors.red;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PionWidget(type: displayColor, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          s.isFinished
                              ? (s.winner == null ? 'Match Nul' : '${s.winner == 'X' ? 'Vert' : 'Rouge'} gagne !')
                              : 'Tour de ${s.turn == 'X' ? 'Vert' : 'Rouge'}',
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }),
                Positioned(
                  right: 0,
                  child: _LocalMuteButton(),
                ),
              ],
            ),
          ),
        ),

        // ─── Joueurs + Indicateur de tour ──────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PlayerLabel(color: 'X', label: 'Vert', isActive: s.turn == 'X' && !s.isFinished),
              // Timer 3s après chaque capture (masque si coudou possible ou pas)
              if (s.localMustContinueFrom != null && !s.isFinished)
                TurnTimerWidget(
                  deadlineEpochMs: s.turnDeadlineEpochMs,
                  maxDurationSeconds: 3,
                )
              else
                Icon(
                  s.isFinished ? Icons.flag_rounded : Icons.swap_horiz_rounded,
                  color: AppColors.yellow.withValues(alpha: 0.5),
                  size: 28,
                ),
              _PlayerLabel(color: 'O', label: 'Rouge', isActive: s.turn == 'O' && !s.isFinished),
            ],
          ),
        ),

        const Spacer(),

        _buildPiecesBar(viewColor == 'X' ? 'O' : 'X', viewColor == 'X' ? oCount : xCount, viewColor == 'X' ? oCaptured : xCaptured),

        // ─── Plateau ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: GameBoardWidget(
            board: s.board,
            yourColor: viewColor,
            isMyTurn: !s.isFinished,
            selectedCell: s.selectedCell,
            validDestinations: s.validDestinations,
            surplaceMode: s.surplaceMode,
            oopsFaultyPositions: s.oopsFaultyPositions,
            chainFromCell: s.localMustContinueFrom,
            onCellClicked: (r, c) {
              if (s.surplaceMode) {
                context.read<LocalGameBloc>().add(LocalSurplaceClicked(r, c));
              } else {
                context.read<LocalGameBloc>().add(LocalCellClicked(r, c));
              }
            },
          ),
        ),

        _buildPiecesBar(viewColor, viewColor == 'X' ? xCount : oCount, viewColor == 'X' ? xCaptured : oCaptured),

        const Spacer(),

        // ─── Actions ────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LocalActionButton(
                icon: s.surplaceMode ? Icons.touch_app_rounded : Icons.replay_rounded,
                label: s.surplaceMode ? 'Annuler' : 'Surplace',
                onTap: s.isFinished
                    ? null
                    : s.surplaceMode
                        ? () => context.read<LocalGameBloc>().add(LocalSurplaceCancelled())
                        : () => context.read<LocalGameBloc>().add(LocalSurplaceRequested()),
              ),
              _LocalActionButton(
                icon: Icons.refresh_rounded,
                label: 'Nouvelle partie',
                onTap: () {
                  setState(() {
                    _showEndOverlay = false;
                    _endSoundPlayed = false;
                  });
                  context.read<LocalGameBloc>().add(LocalNewGame());
                },
              ),
              _LocalActionButton(
                icon: Icons.arrow_back_rounded,
                label: 'Quitter',
                onTap: () => context.pop(),
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

class _PlayerLabel extends StatelessWidget {
  final String color;
  final String label;
  final bool isActive;

  const _PlayerLabel({required this.color, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final avatarColor = color == 'X' ? AppColors.green : AppColors.red;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
            border: Border.all(
              color: isActive ? AppColors.yellow : avatarColor,
              width: 3,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: AppColors.yellow.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)]
                : null,
          ),
          child: Center(child: PionWidget(type: color, size: 36)),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class _LocalActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const _LocalActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
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
                border: isHighlighted ? Border.all(color: AppColors.red, width: 2) : null,
                boxShadow: isHighlighted
                    ? [BoxShadow(color: AppColors.red.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)]
                    : null,
              ),
              child: Icon(icon, color: isHighlighted ? AppColors.red : AppColors.yellow, size: 24),
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

class _LocalMuteButton extends StatefulWidget {
  @override
  State<_LocalMuteButton> createState() => _LocalMuteButtonState();
}

class _LocalMuteButtonState extends State<_LocalMuteButton> {
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
