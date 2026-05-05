import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/service_locator.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class PlayPlaceholderView extends StatelessWidget {
  const PlayPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Jouer - À venir',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

class FriendsPlaceholderView extends StatelessWidget {
  const FriendsPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Amis - À venir',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

class ProfilePlaceholderView extends StatelessWidget {
  const ProfilePlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Profil - À venir',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await sl<AuthRepository>().logout();
              if (context.mounted) {
                context.goNamed('phone');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Se déconnecter', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPlaceholderView extends StatelessWidget {
  const SettingsPlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Réglages - À venir',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
