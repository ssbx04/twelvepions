import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';

/// Champ de saisie du numéro de téléphone sénégalais.
///
/// Affiche un préfixe `🇸🇳 +221` à gauche, un séparateur vertical, puis le
/// numéro saisi auto-formaté en `XX XXX XX XX` (9 chiffres).
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          // ─── Préfixe pays ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Text('🇸🇳', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text('+221', style: AppTextStyles.prefix),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 28,
            color: AppColors.borderSubtle,
          ),
          const SizedBox(width: 12),
          // ─── Numéro ───────────────────────────────────────────────────
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.inputLg,
              cursorColor: AppColors.yellow,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
                _SenegalPhoneFormatter(),
              ],
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: '7X XXX XX XX',
                hintStyle: TextStyle(
                  color: Color(0x66FDEF42),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formate un numéro 9 chiffres au format `XX XXX XX XX`.
class _SenegalPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length && i < 9; i++) {
      // Espaces après les positions 2, 5, 7.
      if (i == 2 || i == 5 || i == 7) buf.write(' ');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
