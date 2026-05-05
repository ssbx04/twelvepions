import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';

/// Avatar circulaire avec les initiales calculées à partir du nom complet.
/// Cercle jaune, texte noir gras.
class AvatarInitials extends StatelessWidget {
  final String fullName;
  final double size;

  const AvatarInitials({
    super.key,
    required this.fullName,
    this.size = 130,
  });

  /// "Cheikh Sadibou SONKO" → "CS"
  /// "Mariama" → "M"
  /// ""        → "?"
  static String computeInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.yellow,
      ),
      alignment: Alignment.center,
      child: Text(
        computeInitials(fullName),
        style: GoogleFonts.dmSans(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
