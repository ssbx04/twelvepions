import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum BannerType { oops, coudou }

/// Bannière animée qui pop avec bounce et shake puis disparaît.
class GameBannerWidget extends StatefulWidget {
  final BannerType type;
  final VoidCallback? onDismissed;

  const GameBannerWidget({
    super.key,
    required this.type,
    this.onDismissed,
  });

  @override
  State<GameBannerWidget> createState() => _GameBannerWidgetState();
}

class _GameBannerWidgetState extends State<GameBannerWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Scale: 0.5 → 1.1 → 0.95 → 1.0 → 1.0 → 0.85
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 15),
    ]).animate(_controller);

    // Opacity: 0 → 1 (quick) → 1 → 0
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_controller);

    // Rotation: 0 → -3° → 3° → -4° → 2° → 0°
    final isOops = widget.type == BannerType.oops;
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: -0.04, end: isOops ? -0.035 : 0.07), weight: 20),
      TweenSequenceItem(tween: Tween(begin: isOops ? -0.035 : 0.07, end: isOops ? 0.035 : -0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: isOops ? 0.035 : -0.05, end: isOops ? -0.07 : 0.035), weight: 20),
      TweenSequenceItem(tween: Tween(begin: isOops ? -0.07 : 0.035, end: 0.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOops = widget.type == BannerType.oops;
    final borderColor = isOops ? AppColors.red : AppColors.green;
    final glowColor = isOops ? AppColors.red : AppColors.green;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Transform.rotate(
              angle: _rotation.value,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xEB2D1810),
          border: Border.all(color: borderColor, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            const BoxShadow(
              color: Color(0x99000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOops ? 'OOPS !' : 'COUDOU !',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: isOops ? 28 : 32,
                letterSpacing: 4,
                color: AppColors.yellow,
                shadows: [
                  Shadow(
                    color: glowColor.withValues(alpha: 0.9),
                    blurRadius: 12,
                  ),
                  const Shadow(
                    color: Color(0xCC000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
            if (isOops) ...[
              const SizedBox(width: 10),
              Text(
                'SURPLACE',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 3,
                  color: const Color(0xFFF4EAD5),
                  shadows: const [
                    Shadow(
                      color: Color(0xCC000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
