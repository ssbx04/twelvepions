import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/bouncing_wrapper.dart';
import '../../domain/entities/game_summary.dart';

class GameHistoryCard extends StatelessWidget {
  final GameSummary game;

  const GameHistoryCard({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final isWin = game.result == 'WIN';
    final isDraw = game.result == 'DRAW';
    final resultColor = isWin ? AppColors.green : isDraw ? AppColors.yellow : AppColors.red;
    final resultLabel = isWin ? 'VICTOIRE' : isDraw ? 'MATCH NUL' : 'DÉFAITE';
    final eloPrefix = game.eloChange >= 0 ? '+' : '';
    final initials = game.opponentUsername.length >= 2
        ? game.opponentUsername.substring(0, 2).toUpperCase()
        : game.opponentUsername.toUpperCase();

    return BouncingWrapper(
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111), // Très sombre, proche du noir
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: resultColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: resultColor.withValues(alpha: 0.05),
              blurRadius: 15,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {}, // Effet de clic
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  // Avatar avec dégradé et lueur interne
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [resultColor.withValues(alpha: 0.2), resultColor.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: resultColor.withValues(alpha: 0.4)),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(color: resultColor, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Textes : Surtitre, Titre, Sous-titre
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resultLabel,
                          style: AppTextStyles.bodySm.copyWith(
                            color: resultColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.opponentUsername,
                          style: AppTextStyles.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Contre ${game.opponentElo} ELO',
                          style: AppTextStyles.bodySm.copyWith(color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                  // Variation ELO
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$eloPrefix${game.eloChange}',
                        style: AppTextStyles.h2.copyWith(
                          color: resultColor,
                          fontSize: 20,
                        ),
                      ),
                      Text('ELO', style: AppTextStyles.bodySm.copyWith(color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
