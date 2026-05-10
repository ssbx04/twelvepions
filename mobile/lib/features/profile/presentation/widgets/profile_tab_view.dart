import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/bouncing_wrapper.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../home/presentation/blocs/home/home_bloc.dart';
import '../../../home/presentation/widgets/game_history_card.dart';

class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.green),
          );
        } else if (state is HomeError) {
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (state is HomeLoaded) {
          final user = state.user;
          final games = state.recentGames;
          
          final wins = games.where((g) => g.result == 'WIN').length;
          final totalGames = games.length;
          final winRate = totalGames > 0 ? (wins / totalGames * 100).round() : 0;

          return SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. En-tête : Avatar et Infos Personnelles
                      _buildHeader(user.fullName ?? user.username ?? 'Joueur', user.username, user.phone),
                      const SizedBox(height: 32),
                      
                      // 2. Section Statistiques ELO
                      _buildStatsSection(user.level?.name ?? 'NOVICE', user.elo, wins, totalGames, winRate),
                      const SizedBox(height: 40),
                      
                      // 3. Historique Complet
                      Text('Historique des parties', style: AppTextStyles.h2.copyWith(fontSize: 18)),
                      const SizedBox(height: 16),
                      if (games.isEmpty)
                        _buildNoGamesPlaceholder()
                      else
                        ...games.map((g) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GameHistoryCard(game: g),
                            )),
                            
                      const SizedBox(height: 40),
                      
                      // 4. Bouton de déconnexion
                      _buildLogoutButton(context),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(String name, String? username, String phone) {
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.green.withValues(alpha: 0.2), AppColors.green.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: AppTextStyles.h1.copyWith(color: AppColors.green, fontSize: 32),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.h1.copyWith(fontSize: 24)),
              if (username != null) ...[
                const SizedBox(height: 4),
                Text('@$username', style: AppTextStyles.body.copyWith(color: AppColors.yellow, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 4),
              Text(phone, style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(String level, int elo, int wins, int totalGames, int winRate) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: AppColors.yellow.withValues(alpha: 0.05), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RANG ACTUEL', style: AppTextStyles.bodySm.copyWith(color: AppColors.yellow, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(level, style: AppTextStyles.h2.copyWith(fontSize: 22, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('$elo', style: AppTextStyles.h1.copyWith(color: AppColors.yellow, fontSize: 36)),
                    const SizedBox(width: 4),
                    Text('ELO', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _buildSmallStatCard('VICTOIRES', '$wins / $totalGames', AppColors.green),
              const SizedBox(height: 16),
              _buildSmallStatCard('WIN RATE', '$winRate%', Colors.blueAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodySm.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 18, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildNoGamesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Aucune partie jouée', style: AppTextStyles.h2.copyWith(fontSize: 18, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Vos statistiques apparaîtront ici.', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return BouncingWrapper(
      child: ElevatedButton.icon(
        onPressed: () async {
          await sl<AuthRepository>().logout();
          if (context.mounted) {
            context.goNamed('phone');
          }
        },
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text('Se déconnecter', style: AppTextStyles.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red.withValues(alpha: 0.9),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}
