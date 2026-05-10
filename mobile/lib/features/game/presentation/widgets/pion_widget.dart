import 'package:flutter/material.dart';

class PionWidget extends StatelessWidget {
  final String type; // 'X', 'x', 'O', 'o'
  final double size;

  const PionWidget({
    super.key,
    required this.type,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    String assetName;
    
    switch (type) {
      case 'X':
        assetName = 'pion_vert.png';
        break;
      case 'x':
        assetName = 'pion_vert_dame.png';
        break;
      case 'O':
        assetName = 'pion_rouge.png';
        break;
      case 'o':
        assetName = 'pion_rouge_dame.png';
        break;
      default:
        return SizedBox(width: size, height: size);
    }

    // Le PNG hérite du viewBox SVG 60x60 où le cercle est à cx=36,cy=24
    // au lieu de 30,30. On compense ce décalage pour centrer visuellement.
    final dx = -size * 0.1;
    final dy = size * 0.1;

    return SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Image.asset(
          'assets/icons/$assetName',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
