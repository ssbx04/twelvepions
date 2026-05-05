import 'dart:ui';

import 'package:flutter/material.dart';

/// Ellipse circulaire au radial gradient + background blur (effet "halo").
///
/// Reproduit l'effet Figma : un cercle rempli d'un radial gradient (alpha
/// max au centre, 0 au bord) avec un `Background blur` derrière.
class BlurEllipse extends StatelessWidget {
  final double size;
  final Color color;

  /// Alpha du centre (0..1). 0.18 = presque imperceptible mais joli halo.
  final double centerAlpha;

  /// Sigma du blur (équivalent du `Background blur` de Figma).
  final double blurSigma;

  const BlurEllipse({
    super.key,
    required this.size,
    required this.color,
    this.centerAlpha = 0.18,
    this.blurSigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: centerAlpha),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}
