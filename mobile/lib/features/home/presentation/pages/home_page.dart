import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/storage/auth_local_storage.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/services/deeplink_service.dart';
import '../../../game/presentation/widgets/tutorial_overlay.dart';
import '../widgets/home_lobby_view.dart';
import '../../../play/presentation/widgets/play_tab_view.dart';
import '../../../friends/presentation/widgets/friends_tab_view.dart';
import '../../../profile/presentation/widgets/profile_tab_view.dart';
import '../widgets/placeholders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _showTutorial = false;
  StreamSubscription<DeeplinkAction>? _deeplinkSub;

  late final List<Widget> _views;

  static const int _tabFriends = 2;
  static const int _tabProfile = 3;

  @override
  void initState() {
    super.initState();
    final deeplink = sl<DeeplinkService>();
    _views = [
      const HomeLobbyView(),
      const PlayTabView(),
      FriendsTabView(subTabNotifier: deeplink.friendsSubTab),
      const ProfileTabView(),
      const SettingsPlaceholderView(),
    ];
    _deeplinkSub = deeplink.stream.listen(_handleDeeplink);
    final pending = deeplink.consumePending();
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeeplink(pending));
    }
    _checkTutorial();
  }

  void _handleDeeplink(DeeplinkAction action) {
    if (!mounted) return;
    setState(() {
      _currentIndex = switch (action) {
        DeeplinkAction.openFriends || DeeplinkAction.openFriendsRequests => _tabFriends,
        DeeplinkAction.openProfile => _tabProfile,
        DeeplinkAction.openHome => 0,
      };
    });
  }

  @override
  void dispose() {
    _deeplinkSub?.cancel();
    super.dispose();
  }

  Future<void> _checkTutorial() async {
    final storage = sl<AuthLocalStorage>();
    final hasSeen = await storage.readHasSeenTutorial();
    if (!hasSeen && mounted) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  void _dismissTutorial() async {
    setState(() {
      _showTutorial = false;
    });
    final storage = sl<AuthLocalStorage>();
    await storage.writeHasSeenTutorial(true);
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildIcon(String name, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: SvgPicture.asset(
        'assets/icons/$name.svg',
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          isActive ? AppColors.yellow : AppColors.textSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppBackground(
            // On peut ajuster l'emplacement des ellipses selon l'onglet
            greenOffset: const Offset(160, -50),
            redOffset: const Offset(-180, 500),
            child: IndexedStack(
              index: _currentIndex,
              children: _views,
            ),
          ),
          if (_showTutorial)
            TutorialOverlay(onDismiss: _dismissTutorial),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF160D07),
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: AppColors.yellow,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          unselectedLabelStyle: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w400,
            fontSize: 10,
          ),
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon('home'),
              activeIcon: _buildIcon('home', isActive: true),
              label: 'ACCUEIL',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('play'),
              activeIcon: _buildIcon('play', isActive: true),
              label: 'JOUER',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('friends'),
              activeIcon: _buildIcon('friends', isActive: true),
              label: 'AMIS',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('profil'),
              activeIcon: _buildIcon('profil', isActive: true),
              label: 'PROFIL',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon('settings'),
              activeIcon: _buildIcon('settings', isActive: true),
              label: 'RÉGLAGES',
            ),
          ],
        ),
      ),
    );
  }
}
