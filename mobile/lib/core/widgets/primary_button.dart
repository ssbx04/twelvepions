import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Bouton principal de l'app : pill jaune avec texte noir, ou désactivé.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Widget? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Material(
        color: enabled
            ? AppColors.yellow
            : AppColors.yellow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.black,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label.toUpperCase(), style: AppTextStyles.button),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 10),
                        trailingIcon!,
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
