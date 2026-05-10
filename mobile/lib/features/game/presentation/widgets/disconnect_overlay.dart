import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class DisconnectOverlay extends StatefulWidget {
  final int forfeitDeadlineEpochMs;

  const DisconnectOverlay({
    super.key,
    required this.forfeitDeadlineEpochMs,
  });

  @override
  State<DisconnectOverlay> createState() => _DisconnectOverlayState();
}

class _DisconnectOverlayState extends State<DisconnectOverlay> {
  late Timer _timer;
  int _secondsLeft = 30;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final left = widget.forfeitDeadlineEpochMs - nowMs;
    setState(() {
      _secondsLeft = (left / 1000).ceil().clamp(0, 30);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        color: AppColors.red,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Adversaire déconnecté',
                      style: AppTextStyles.h2.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'En attente de reconnexion...',
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '00:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: AppTextStyles.h2.copyWith(color: Colors.white, fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'S\'il ne revient pas, vous gagnerez par forfait.',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
