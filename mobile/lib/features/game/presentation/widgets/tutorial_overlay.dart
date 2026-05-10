import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/primary_button.dart';

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({super.key, required this.onDismiss});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Le 12 Pions',
      'body': 'Ce jeu traditionnel sénégalais ressemble aux dames. Vos pions peuvent se déplacer d\'une case vers une case libre, en ligne droite ou en diagonale.',
      'icon': 'gamepad',
    },
    {
      'title': 'La Capture',
      'body': 'Pour capturer un pion adverse, sautez par-dessus si la case derrière lui est vide. Vous pouvez enchaîner plusieurs captures !',
      'icon': 'flash_on',
    },
    {
      'title': 'Le Surplace (Oops !)',
      'body': 'Particularité du jeu : la capture n\'est PAS obligatoire. Mais si vous "oubliez" de capturer, votre adversaire peut réclamer la pièce fautive. Restez concentré !',
      'icon': 'warning_amber_rounded',
    },
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161C19),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (idx) => setState(() => _currentPage = idx),
                          itemCount: _slides.length,
                          itemBuilder: (context, index) {
                            final slide = _slides[index];
                            final isWarning = index == 2;
                            final color = isWarning ? AppColors.yellow : AppColors.green;
                            
                            IconData iconData = Icons.gamepad;
                            if (slide['icon'] == 'flash_on') iconData = Icons.flash_on;
                            if (slide['icon'] == 'warning_amber_rounded') iconData = Icons.warning_amber_rounded;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconData, color: color, size: 40),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  slide['title']!,
                                  style: AppTextStyles.h2.copyWith(color: color, fontSize: 22),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  slide['body']!,
                                  style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? AppColors.green : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: _currentPage == _slides.length - 1 ? 'J\'ai compris' : 'Suivant',
                        onPressed: _nextPage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
