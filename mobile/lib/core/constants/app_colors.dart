import 'package:flutter/material.dart';

/// Palette officielle de l'app, basée sur le drapeau du Sénégal.
class AppColors {
  AppColors._();

  // ─── Drapeau Sénégal ───────────────────────────────────────────────────────

  static const Color green = Color(0xFF00853F);
  static const Color yellow = Color(0xFFFDEF42);
  static const Color red = Color(0xFFE31B23);

  // ─── Fond (template) ───────────────────────────────────────────────────────

  /// Couleur de départ du linear gradient global.
  static const Color bgGradientStart = Color(0xFF1A0F08);

  /// Couleur de fin du linear gradient global.
  static const Color bgGradientEnd = Color(0xFF2D1810);

  // ─── Neutres ───────────────────────────────────────────────────────────────

  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCFD6E0);
  static const Color textMuted = Color(0xFF9AA0B0);

  // ─── Composants ────────────────────────────────────────────────────────────

  /// Bordure subtile pour les inputs et cartes.
  static Color borderSubtle = white.withValues(alpha: 0.12);
}
