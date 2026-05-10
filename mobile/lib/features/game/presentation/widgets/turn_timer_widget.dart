import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class TurnTimerWidget extends StatefulWidget {
  final int? deadlineEpochMs;
  final int maxDurationSeconds;

  const TurnTimerWidget({
    super.key,
    required this.deadlineEpochMs,
    this.maxDurationSeconds = 30,
  });

  @override
  State<TurnTimerWidget> createState() => _TurnTimerWidgetState();
}

class _TurnTimerWidgetState extends State<TurnTimerWidget>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  double _progress = 0.0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant TurnTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineEpochMs != widget.deadlineEpochMs) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateTime();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _updateTime());
  }

  void _updateTime() {
    if (widget.deadlineEpochMs == null) {
      if (mounted) {
        setState(() {
          _remainingSeconds = widget.maxDurationSeconds;
          _progress = 1.0;
        });
        _pulseController.stop();
        _pulseController.reset();
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = widget.deadlineEpochMs! - now;
    
    if (diff <= 0) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _remainingSeconds = 0;
          _progress = 0.0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _remainingSeconds = (diff / 1000).ceil();
        _progress = diff / (widget.maxDurationSeconds * 1000);
      });

      // Pulse when < 5 seconds
      if (_remainingSeconds <= 5 && !_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      } else if (_remainingSeconds > 5 && _pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = _remainingSeconds <= 5 && _remainingSeconds > 0;
    final timerColor = isWarning ? AppColors.red : AppColors.yellow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return Transform.scale(
              scale: isWarning ? _pulseAnim.value : 1.0,
              child: child,
            );
          },
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: _progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: timerColor,
                ),
                Center(
                  child: Icon(
                    Icons.timer_outlined,
                    color: timerColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '00:${_remainingSeconds.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: timerColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
