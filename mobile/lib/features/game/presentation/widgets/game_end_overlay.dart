import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum GameEndResult { victory, defeat, draw }

/// Overlay de fin de partie : confettis (victoire), pluie (défaite), ou texte neutre (nul).
class GameEndOverlay extends StatefulWidget {
  final GameEndResult result;
  final VoidCallback? onReplay;
  final VoidCallback? onQuit;
  /// En mode local : le nom du gagnant (ex: "Vert (X)") et sa couleur
  final String? winnerLabel;
  final Color? winnerColor;

  const GameEndOverlay({
    super.key,
    required this.result,
    this.onReplay,
    this.onQuit,
    this.winnerLabel,
    this.winnerColor,
  });

  @override
  State<GameEndOverlay> createState() => _GameEndOverlayState();
}

class _GameEndOverlayState extends State<GameEndOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _textController;
  late final AnimationController _particleController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _textScale;
  late final Animation<double> _textOpacity;

  final List<_Particle> _particles = [];
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();

    // Fond qui s'assombrit
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    // Texte qui bounce
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.3)),
    );

    // Particules (confetti ou pluie)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _initParticles();
        _particleController.forward();
      }
    });
  }

  void _initParticles() {
    _particles.clear();
    if (widget.result == GameEndResult.victory) {
      // Confettis
      const colors = [Color(0xFF00853F), Color(0xFFFDEF42), Color(0xFFE31B23), Colors.white];
      for (int i = 0; i < 120; i++) {
        _particles.add(_Particle(
          x: _rng.nextDouble(),
          y: -0.1 - _rng.nextDouble() * 0.5,
          vx: (_rng.nextDouble() - 0.5) * 0.008,
          vy: 0.003 + _rng.nextDouble() * 0.006,
          size: 5 + _rng.nextDouble() * 5,
          color: colors[_rng.nextInt(colors.length)],
          rotation: _rng.nextDouble() * pi * 2,
          vr: (_rng.nextDouble() - 0.5) * 0.08,
          isRect: _rng.nextBool(),
        ));
      }
    } else if (widget.result == GameEndResult.defeat) {
      // Pluie
      for (int i = 0; i < 80; i++) {
        _particles.add(_Particle(
          x: _rng.nextDouble(),
          y: -_rng.nextDouble(),
          vx: 0.0002,
          vy: 0.004 + _rng.nextDouble() * 0.004,
          size: 12 + _rng.nextDouble() * 16,
          color: const Color(0xFF7A8090),
          rotation: 0,
          vr: 0,
          isRect: true,
        ));
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _textController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fond sombre
        FadeTransition(
          opacity: _fadeAnim,
          child: Container(
            color: widget.result == GameEndResult.defeat
                ? const Color(0xCC050208)
                : const Color(0x88000000),
          ),
        ),

        // Particules
        if (widget.result != GameEndResult.draw)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  isConfetti: widget.result == GameEndResult.victory,
                ),
              );
            },
          ),

        // Texte + Boutons avec fond
        Center(
          child: AnimatedBuilder(
            animation: _textController,
            builder: (context, child) {
              return Opacity(
                opacity: _textOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _textScale.value,
                  child: child,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xDD0A0E1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.result == GameEndResult.defeat
                      ? const Color(0xFF3A3A4A)
                      : AppColors.yellow.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultText(),
                  const SizedBox(height: 12),
                  _buildSubText(),
                  const SizedBox(height: 36),
                  _buildButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultText() {
    // Mode local : afficher qui a gagné
    if (widget.winnerLabel != null && widget.result == GameEndResult.victory) {
      return Text(
        '${widget.winnerLabel} gagne !',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: widget.winnerColor ?? AppColors.yellow,
          shadows: [
            Shadow(color: (widget.winnerColor ?? AppColors.green).withValues(alpha: 0.9), blurRadius: 20),
            const Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
      );
    }

    switch (widget.result) {
      case GameEndResult.victory:
        return Text(
          'VICTOIRE !',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 6,
            color: AppColors.yellow,
            shadows: [
              Shadow(color: AppColors.green.withValues(alpha: 0.9), blurRadius: 20),
              const Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
        );
      case GameEndResult.defeat:
        return Text(
          'défaite',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            fontStyle: FontStyle.italic,
            letterSpacing: 8,
            color: const Color(0xFF9AA0B0),
            shadows: [
              Shadow(color: const Color(0xFF78505A).withValues(alpha: 0.4), blurRadius: 30),
              const Shadow(color: Color(0xF0000000), blurRadius: 18, offset: Offset(0, 4)),
            ],
          ),
        );
      case GameEndResult.draw:
        return Text(
          'MATCH NUL',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: 5,
            color: AppColors.yellow,
            shadows: const [
              Shadow(color: Color(0xCC000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
        );
    }
  }

  Widget _buildSubText() {
    // Mode local : pas de sous-texte personnalisé
    if (widget.winnerLabel != null && widget.result == GameEndResult.victory) {
      return Text(
        'Bien joué !',
        style: TextStyle(
          fontSize: 14,
          letterSpacing: 3,
          color: const Color(0xCCF4EAD5),
        ),
      );
    }

    String text;
    switch (widget.result) {
      case GameEndResult.victory:
        text = 'Bravo, champion !';
      case GameEndResult.defeat:
        text = 'la prochaine sera la bonne';
      case GameEndResult.draw:
        text = 'Égalité parfaite';
    }
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        letterSpacing: 3,
        color: widget.result == GameEndResult.defeat
            ? const Color(0xFF6A7080)
            : const Color(0xCCF4EAD5),
        fontStyle: widget.result == GameEndResult.defeat ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.onReplay != null)
          _EndButton(
            label: 'Rejouer',
            icon: Icons.replay_rounded,
            color: AppColors.green,
            onTap: widget.onReplay!,
          ),
        if (widget.onReplay != null && widget.onQuit != null)
          const SizedBox(width: 16),
        if (widget.onQuit != null)
          _EndButton(
            label: 'Quitter',
            icon: Icons.exit_to_app_rounded,
            color: AppColors.red,
            onTap: widget.onQuit!,
          ),
      ],
    );
  }
}

class _EndButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EndButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Particle system ---

class _Particle {
  double x, y, vx, vy, size, rotation, vr;
  Color color;
  bool isRect;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.vr,
    required this.isRect,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool isConfetti;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.isConfetti,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fadeStart = 0.75;
    final globalAlpha = progress > fadeStart
        ? ((1.0 - progress) / (1.0 - fadeStart)).clamp(0.0, 1.0)
        : 1.0;

    for (final p in particles) {
      // Simulate
      p.x += p.vx;
      p.y += p.vy;
      if (isConfetti) p.vy += 0.00008; // gravity
      p.rotation += p.vr;
      if (p.y > 1.2) { p.y = -0.1; p.x = Random().nextDouble(); }

      final px = p.x * size.width;
      final py = p.y * size.height;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final paint = Paint()
        ..color = p.color.withValues(alpha: globalAlpha * (isConfetti ? 0.9 : 0.35))
        ..style = isConfetti ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = isConfetti ? 0 : 1.4;

      if (isConfetti) {
        if (p.isRect) {
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
        } else {
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
        }
      } else {
        // Rain drop
        canvas.drawLine(Offset.zero, Offset(1, p.size), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}
