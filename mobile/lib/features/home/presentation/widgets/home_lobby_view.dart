import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../blocs/home/home_bloc.dart';

class HomeLobbyView extends StatelessWidget {
  const HomeLobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.green));
        }
        
        final user = state is HomeLoaded ? state.user : null;
        final elo = user?.elo.toString() ?? '...';
        final name = user?.fullName?.split(' ')?.first ?? 'Joueur';

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(elo),
                const SizedBox(height: 32),
                _buildGreeting(name),
                const SizedBox(height: 24),
                _buildPlayCTA(),
                const SizedBox(height: 24),
                _buildMariamaCard(),
                const SizedBox(height: 24),
                _buildLastGameCard(),
                const SizedBox(height: 32),
                _buildOnlineFriends(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // 1. Header (Logo + ELO Pill)
  Widget _buildHeader(String elo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SvgPicture.asset(
          'assets/logos/logo.svg',
          height: 24,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.yellow.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.yellow, size: 16),
              const SizedBox(width: 6),
              Text(
                elo,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.yellow,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Greeting
  Widget _buildGreeting(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour $name 👋',
          style: AppTextStyles.h1.copyWith(fontSize: 26),
        ),
        const SizedBox(height: 6),
        Text(
          'Prêt pour une nouvelle victoire ?',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 3. Play CTA with 3D Pawns
  Widget _buildPlayCTA() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF00642F), Color(0xFF003D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Pawns Images
            Positioned(
              right: -20,
              bottom: -10,
              child: Image.asset(
                'assets/images/pion_green.png',
                width: 120,
              ),
            ),
            Positioned(
              right: 40,
              top: -10,
              child: Image.asset(
                'assets/images/pion_rouge.png',
                width: 90,
              ),
            ),
            // Text Content
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                  const Spacer(),
                  Text(
                    'JOUER MAINTENANT',
                    style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Match rapide en ligne',
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Mariama Card
  Widget _buildMariamaCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1A12), // Subtle yellow-ish dark background
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withValues(alpha: 0.05),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
              ),
              child: SvgPicture.asset(
                'assets/logos/mariama.svg',
                height: 24,
                width: 24,
                colorFilter: const ColorFilter.mode(AppColors.yellow, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Affronter Mariama', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Entraînement hors-ligne', style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.yellow),
          ],
        ),
      ),
    );
  }

  // 5. Last Game Card
  Widget _buildLastGameCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121A16), // Subtle green-ish dark background
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dernière partie', style: AppTextStyles.subtitle.copyWith(color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('+14 ELO', style: AppTextStyles.bodySm.copyWith(color: AppColors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.red,
                    radius: 20,
                    child: Text('MO', style: AppTextStyles.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Victoire !', style: AppTextStyles.bodyLg.copyWith(color: AppColors.green, fontWeight: FontWeight.bold)),
                    Text('Contre Mamadou', style: AppTextStyles.bodySm),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                ),
                child: const Text('Revoir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Online Friends
  Widget _buildOnlineFriends() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Amis en ligne (2)', style: AppTextStyles.h2.copyWith(fontSize: 18)),
            Text('Voir tout', style: AppTextStyles.linkSm),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildFriendItem('CS', AppColors.green, 'Cheikh'),
              const SizedBox(width: 24),
              _buildFriendItem('IB', AppColors.yellow, 'Ibrahima', textColor: Colors.black),
              const SizedBox(width: 24),
              _buildAddFriendItem(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendItem(String initials, Color bgColor, String name, {Color textColor = Colors.white}) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: bgColor,
                child: Text(initials, style: AppTextStyles.bodyLg.copyWith(color: textColor, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A0F08), width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name, style: AppTextStyles.bodySm),
      ],
    );
  }

  Widget _buildAddFriendItem() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.borderSubtle, style: BorderStyle.solid),
          ),
          child: const Icon(Icons.add, color: AppColors.textSecondary, size: 28),
        ),
        const SizedBox(height: 8),
        Text('Ajouter', style: AppTextStyles.bodySm),
      ],
    );
  }
}
