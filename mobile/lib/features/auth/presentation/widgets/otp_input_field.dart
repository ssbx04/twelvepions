import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

/// Champ de saisie OTP : N cases (6 par défaut), auto-advance focus,
/// backspace recule, support paste.
class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onCompleted;
  final bool enabled;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onChanged,
    this.onCompleted,
    this.enabled = true,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String _currentCode() => _controllers.map((c) => c.text).join();

  void _emit() {
    final code = _currentCode();
    widget.onChanged(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  void _onChanged(int index, String value) {
    // Cas du paste : plusieurs chiffres dans un champ.
    if (value.length > 1) {
      _distributeFrom(index, value);
      return;
    }
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _emit();
  }

  /// Si l'utilisateur colle un code complet, on répartit chaque digit dans
  /// les cases qui suivent et on focus la dernière (ou onCompleted).
  void _distributeFrom(int startIndex, String pasted) {
    final digits = pasted.replaceAll(RegExp(r'\D'), '');
    var pos = startIndex;
    for (var i = 0; i < digits.length && pos < widget.length; i++) {
      _controllers[pos].text = digits[i];
      pos++;
    }
    final lastFilled = (pos - 1).clamp(0, widget.length - 1);
    final nextIndex = pos < widget.length ? pos : lastFilled;
    _focusNodes[nextIndex].requestFocus();
    _emit();
  }

  /// Backspace dans une case vide : reculer + effacer la précédente.
  void _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) => _OtpBox(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            enabled: widget.enabled,
            onChanged: (v) => _onChanged(i, v),
            onKey: (e) => _onKey(i, e),
          )),
    );
  }
}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;
  final bool enabled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
    required this.enabled,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});
  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.controller.text.isNotEmpty;
    final hasFocus = widget.focusNode.hasFocus;
    final highlight = hasValue || hasFocus;

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: widget.onKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight ? AppColors.yellow : AppColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            cursorColor: AppColors.yellow,
            cursorWidth: 1.5,
            style: const TextStyle(
              color: AppColors.yellow,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: widget.onChanged,
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    );
  }
}
