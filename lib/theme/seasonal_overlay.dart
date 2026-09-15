import 'dart:math';
import 'package:flutter/material.dart';

class SeasonalOverlay extends StatefulWidget {
  final Widget child;
  final String seasonMode;
  final String intensity;

  const SeasonalOverlay({
    super.key,
    required this.child,
    required this.seasonMode,
    this.intensity = 'MEDIUM',
  });

  @override
  State<SeasonalOverlay> createState() => _SeasonalOverlayState();
}

class _SeasonalOverlayState extends State<SeasonalOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_particles.isEmpty && _shouldShowParticles()) {
      _initParticles();
    }
  }

  @override
  void didUpdateWidget(SeasonalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seasonMode != widget.seasonMode ||
        oldWidget.intensity != widget.intensity) {
      if (_shouldShowParticles()) {
        _initParticles();
      } else {
        setState(() {
          _particles = [];
        });
      }
    }
  }

  String _resolveEffectiveSeason() {
    final mode = widget.seasonMode.toUpperCase();
    if (mode == 'NONE') return 'NONE';
    if (mode == 'AUTO') {
      final month = DateTime.now().month;
      if (month == 10 || month == 11) return 'DIWALI';
      if (month == 12 || month == 1 || month == 2) return 'WINTER';
      if (month == 3 || month == 4) return 'SPRING';
      if (month == 5 || month == 6) return 'SUMMER';
      if (month >= 7 && month <= 9) return 'MONSOON';
      return 'WINTER';
    }
    return mode;
  }

  bool _shouldShowParticles() {
    final effective = _resolveEffectiveSeason();
    return effective != 'NONE';
  }

  void _initParticles() {
    int count = 30;
    if (widget.intensity == 'LOW') count = 15;
    if (widget.intensity == 'HIGH') count = 60;

    _particles = List.generate(count, (index) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.1 + _random.nextDouble() * 0.3,
        size: 2.0 + _random.nextDouble() * 4.0,
        type: _getParticleType(),
      );
    });
  }

  String _getParticleType() {
    final effective = _resolveEffectiveSeason();
    switch (effective) {
      case 'WINTER':
      case 'CHRISTMAS':
        return 'SNOW';
      case 'MONSOON':
        return 'RAIN';
      case 'SPRING':
        return 'PETAL';
      case 'DIWALI':
        return 'SPARKLE';
      case 'SUMMER':
        return 'SUNSHINE';
      default:
        return 'SNOW';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShowParticles()) return widget.child;

    final effectiveSeason = _resolveEffectiveSeason();

    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _SeasonalPainter(
                  particles: _particles,
                  progress: _controller.value,
                  seasonMode: effectiveSeason,
                ),
                child: Container(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double size;
  String type;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.type,
  });
}

class _SeasonalPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final String seasonMode;

  _SeasonalPainter({
    required this.particles,
    required this.progress,
    required this.seasonMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      // Calculate current Y based on progress and speed
      double currentY = (particle.y + (progress * particle.speed * 10)) % 1.0;
      double currentX = particle.x;

      // Add a little horizontal sway for snow, petals and sparkles
      if (particle.type == 'SNOW' || particle.type == 'PETAL' || particle.type == 'SPARKLE') {
        currentX = (particle.x + sin(progress * pi * 2 + particle.y * 10) * 0.05) % 1.0;
      }

      double px = currentX * size.width;
      double py = currentY * size.height;

      switch (particle.type) {
        case 'SNOW':
          paint.color = Colors.white.withValues(alpha: 0.65);
          canvas.drawCircle(Offset(px, py), particle.size, paint);
          break;
        case 'RAIN':
          paint.color = Colors.lightBlueAccent.withValues(alpha: 0.5);
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(px, py),
              width: particle.size * 0.4,
              height: particle.size * 3.5,
            ),
            paint,
          );
          break;
        case 'PETAL':
          paint.color = Colors.pinkAccent.withValues(alpha: 0.6);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(px, py),
              width: particle.size * 1.5,
              height: particle.size * 1.0,
            ),
            paint,
          );
          break;
        case 'SPARKLE':
          // Golden glowing sparkle for Diwali
          paint.color = Colors.amber.withValues(alpha: 0.85);
          canvas.drawCircle(Offset(px, py), particle.size * 0.8, paint);
          paint.color = Colors.orangeAccent.withValues(alpha: 0.4);
          canvas.drawCircle(Offset(px, py), particle.size * 1.6, paint);
          break;
        case 'SUNSHINE':
          // Warm glowing sunbeam shimmer
          paint.color = Colors.yellow.withValues(alpha: 0.4);
          canvas.drawCircle(Offset(px, py), particle.size * 1.5, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SeasonalPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
