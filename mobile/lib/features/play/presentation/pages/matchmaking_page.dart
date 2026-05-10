import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/app_background.dart';
import '../blocs/matchmaking/matchmaking_bloc.dart';

class MatchmakingPage extends StatelessWidget {
  final bool isAi;
  const MatchmakingPage({super.key, this.isAi = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MatchmakingBloc>(
      create: (_) {
        final bloc = sl<MatchmakingBloc>();
        if (isAi) {
          bloc.add(MatchmakingJoinAiQueue());
        } else {
          bloc.add(MatchmakingJoinQueue());
        }
        return bloc;
      },
      child: const _MatchmakingView(),
    );
  }
}

class _MatchmakingView extends StatefulWidget {
  const _MatchmakingView();

  @override
  State<_MatchmakingView> createState() => _MatchmakingViewState();
}

class _MatchmakingViewState extends State<_MatchmakingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _cancelSearch() {
    context.read<MatchmakingBloc>().add(MatchmakingLeaveQueue());
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        greenOffset: const Offset(200, -50),
        redOffset: const Offset(-200, 400),
        child: SafeArea(
          child: BlocConsumer<MatchmakingBloc, MatchmakingState>(
            listener: (context, state) {
              if (state is MatchmakingMatched) {
                // Naviguer vers la page de jeu avec l'ID et la couleur
                context.pushReplacementNamed(
                  'game',
                  pathParameters: {'gameId': state.gameId},
                  extra: {'yourColor': state.yourColor, 'stateData': state.stateData},
                );
              } else if (state is MatchmakingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message, style: const TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.red,
                  ),
                );
                context.pop(); // Retour au lobby en cas d'erreur
              }
            },
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Animation Radar
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildPulse(0.0),
                          _buildPulse(0.33),
                          _buildPulse(0.66),
                          // Avatar / Icon central
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                              border: Border.all(color: AppColors.yellow, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withValues(alpha: 0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.search,
                              color: AppColors.yellow,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Recherche d\'un adversaire...',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Veuillez patienter',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const Spacer(),
                  // Bouton Annuler
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                    child: TextButton(
                      onPressed: _cancelSearch,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Annuler', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPulse(double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        // Décalage du cycle pour chaque cercle
        double progress = (_pulseController.value + delay) % 1.0;
        
        // La taille augmente de 0.3 à 1.0
        double scale = 0.3 + (progress * 0.7);
        
        // L'opacité diminue de 0.8 à 0.0
        double opacity = 0.8 * (1.0 - progress);

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.yellow.withValues(alpha: opacity),
                width: 2,
              ),
              color: AppColors.yellow.withValues(alpha: opacity * 0.2),
            ),
          ),
        );
      },
    );
  }
}
