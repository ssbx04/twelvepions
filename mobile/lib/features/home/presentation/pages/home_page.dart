import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_background.dart';
import '../widgets/home_lobby_view.dart';
import '../widgets/placeholders.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    HomeLobbyView(),
    PlayPlaceholderView(),
    FriendsPlaceholderView(),
    ProfilePlaceholderView(),
    SettingsPlaceholderView(),
  ];

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
      body: AppBackground(
        // On peut ajuster l'emplacement des ellipses selon l'onglet
        greenOffset: const Offset(160, -50),
        redOffset: const Offset(-180, 500),
        child: IndexedStack(
          index: _currentIndex,
          children: _views,
        ),
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
