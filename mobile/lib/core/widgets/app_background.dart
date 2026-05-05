import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'blur_ellipse.dart';

/// Fond commun à toutes les pages : linear gradient sombre + 2 petits blurs
/// décoratifs (vert et rouge) repositionnables par page.
class AppBackground extends StatelessWidget {
  /// Décalage du blur vert décoratif (coin supérieur gauche par défaut).
  final Offset greenOffset;

  /// Décalage du blur rouge décoratif.
  final Offset redOffset;

  /// Taille des petits blurs décoratifs (ne pas confondre avec les grosses
  /// ellipses du splash).
  final double smallEllipseSize;

  /// Permet de masquer entièrement les blurs décoratifs (utile pour les pages
  /// qui ont leurs propres grosses ellipses, ex. splash).
  final bool showDecorativeEllipses;

  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
    this.greenOffset = const Offset(160, 440),
    this.redOffset = const Offset(-180, 70),
    this.smallEllipseSize = 400,
    this.showDecorativeEllipses = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgGradientStart, AppColors.bgGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          if (showDecorativeEllipses) ...[
            Positioned(
              left: greenOffset.dx,
              top: greenOffset.dy,
              child: BlurEllipse(
                size: smallEllipseSize,
                color: AppColors.green,
              ),
            ),
            Positioned(
              left: redOffset.dx,
              top: redOffset.dy,
              child: BlurEllipse(
                size: smallEllipseSize,
                color: AppColors.red,
              ),
            ),
          ],
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
