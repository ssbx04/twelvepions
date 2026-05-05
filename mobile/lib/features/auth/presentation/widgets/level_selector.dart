import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/user_level.dart';

/// Sélecteur de niveau : 4 pills (Débutant / Intermédiaire / Avancé / Expert).
/// Le sélectionné a un fond jaune et texte noir.
class LevelSelector extends StatelessWidget {
  final UserLevel? selected;
  final ValueChanged<UserLevel> onChanged;

  const LevelSelector({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          for (final level in UserLevel.values)
            Expanded(child: _LevelPill(
              level: level,
              isSelected: level == selected,
              onTap: () => onChanged(level),
            )),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final UserLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  const _LevelPill({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.yellow : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          level.label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySm.copyWith(
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
