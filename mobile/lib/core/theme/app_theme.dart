import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Thème global de l'application (DM Sans + couleurs Sénégal).
class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.dmSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.green,
        secondary: AppColors.yellow,
        error: AppColors.red,
        surface: AppColors.bgGradientEnd,
      ),
    );
  }
}
