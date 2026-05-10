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
