import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/bouncing_wrapper.dart';
import '../../../../features/friends/domain/entities/friend.dart';
import '../../../../features/friends/presentation/blocs/friends_bloc.dart';
import '../../domain/entities/game_summary.dart';
import '../blocs/home/home_bloc.dart';
import 'game_history_card.dart';

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
        final recentGames = state is HomeLoaded ? state.recentGames : <GameSummary>[];
        final elo = user?.elo.toString() ?? '...';
        final name = user?.fullName?.split(' ').first ?? 'Joueur';

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
                _buildPlayCTA(context),
                const SizedBox(height: 24),
                _MariamaCard(),
                const SizedBox(height: 24),
                _buildOnlineFriends(),
                const SizedBox(height: 16),
                _buildLocalCard(context),
                const SizedBox(height: 24),
                _buildRecentGamesSection(recentGames),
                const SizedBox(height: 32),
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
        SvgPicture.asset('assets/logos/logo.svg', height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: AppColors.yellow.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppColors.yellow.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: AppColors.yellow, size: 16),
              const SizedBox(width: 6),
              Text(elo, style: AppTextStyles.body.copyWith(color: AppColors.yellow, fontWeight: FontWeight.bold)),
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
        Text('Bonjour $name 👋', style: AppTextStyles.h1.copyWith(fontSize: 26)),
        const SizedBox(height: 6),
        Text('Prêt pour une nouvelle victoire ?', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }

  // 3. Play CTA
  Widget _buildPlayCTA(BuildContext context) {
    return BouncingWrapper(
      child: GestureDetector(
        onTap: () async {
          await context.pushNamed('matchmaking');
          if (context.mounted) {
            context.read<HomeBloc>().add(const HomeStarted());
          }
        },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF00642F), Color(0xFF003D1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.5), width: 1),
          boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -10,
              child: Image.asset('assets/images/pion_green.png', width: 120),
            ),
            Positioned(
              right: 40,
              top: -10,
              child: Image.asset('assets/images/pion_rouge.png', width: 90),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                  ),
                  const Spacer(),
                  Text('JOUER MAINTENANT', style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('Match rapide en ligne', style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }


  // 4b. Local 2 Players Card
  Widget _buildLocalCard(BuildContext context) {
    return BouncingWrapper(
      child: GestureDetector(
        onTap: () async {
          await context.pushNamed('local-game');
          if (context.mounted) {
            context.read<HomeBloc>().add(const HomeStarted());
          }
        },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1218),
          border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppColors.red.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.people_rounded, color: AppColors.red, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2 Joueurs', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Sur le même téléphone', style: AppTextStyles.bodySm),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.red),
          ],
        ),
      ),
    ));
  }

  // 5. Section historique des parties
  Widget _buildRecentGamesSection(List<GameSummary> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Parties récentes', style: AppTextStyles.h2.copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        if (games.isEmpty)
          _buildNoGamesPlaceholder()
        else
          ...games.take(3).map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GameHistoryCard(game: g),
              )),
      ],
    );
  }

  Widget _buildNoGamesPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF121A16),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.sports_esports_rounded, color: AppColors.green.withValues(alpha: 0.4), size: 36),
            const SizedBox(height: 12),
            Text('Pas encore de partie jouée', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Lance une partie pour commencer !', style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // 6. Online Friends
  Widget _buildOnlineFriends() {
    return BlocBuilder<FriendsBloc, FriendsState>(
      builder: (context, state) {
        final onlineFriends = state.friends
            .where((f) => f.presence == Presence.online || f.presence == Presence.inGame)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  onlineFriends.isEmpty ? 'Amis en ligne' : 'Amis en ligne (${onlineFriends.length})',
                  style: AppTextStyles.h2.copyWith(fontSize: 18),
                ),
                Text('Voir tout', style: AppTextStyles.linkSm),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...onlineFriends.map((f) => Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: _FriendAvatarItem(friend: f),
                      )),
                  _buildAddFriendItem(),
                ],
              ),
            ),
          ],
        );
      },
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

class _FriendAvatarItem extends StatelessWidget {
  final Friend friend;
  const _FriendAvatarItem({required this.friend});

  @override
  Widget build(BuildContext context) {
    final parts = (friend.fullName ?? friend.username).trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : friend.username.substring(0, friend.username.length.clamp(0, 2)).toUpperCase();

    final dotColor = friend.presence == Presence.inGame ? AppColors.yellow : AppColors.green;
    final borderColor = friend.presence == Presence.inGame ? AppColors.yellow : AppColors.green;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [BoxShadow(color: borderColor.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.yellow,
                child: Text(initials, style: AppTextStyles.bodyLg.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A0F08), width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          friend.username.length > 7 ? '${friend.username.substring(0, 6)}…' : friend.username,
          style: AppTextStyles.bodySm,
        ),
      ],
    );
  }
}

class _MariamaCard extends StatefulWidget {
  @override
  State<_MariamaCard> createState() => _MariamaCardState();
}

class _MariamaCardState extends State<_MariamaCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return BouncingWrapper(
          child: GestureDetector(
            onTap: () async {
              await context.pushNamed('matchmaking', extra: {'ai': true});
              if (context.mounted) {
                context.read<HomeBloc>().add(const HomeStarted());
              }
            },
            child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2A2215), Color(0xFF15110A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.yellow.withValues(alpha: _glowAnimation.value)),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withValues(alpha: _glowAnimation.value * 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.yellow.withValues(alpha: _glowAnimation.value)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.yellow.withValues(alpha: _glowAnimation.value * 0.5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: SvgPicture.asset('assets/logos/mariama.svg', height: 26, width: 26,
                      colorFilter: const ColorFilter.mode(AppColors.yellow, BlendMode.srcIn)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Affronter Mariama', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.bold, color: AppColors.yellow)),
                      const SizedBox(height: 4),
                      Text('Intelligence Artificielle', style: AppTextStyles.bodySm.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('IA', style: AppTextStyles.bodySm.copyWith(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.bolt, color: AppColors.yellow),
              ],
            ),
          ),
        ));
      },
    );
  }
}

