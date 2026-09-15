import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlowingBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;
  final List<Color> colors;

  const GlowingBorder({
    super.key,
    required this.child,
    this.borderWidth = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.colors = const [
      Color(0xFFF43F5E),
      Color(0xFF8B5CF6),
      Color(0xFF3B82F6),
      Color(0xFFF43F5E),
    ],
  });

  @override
  State<GlowingBorder> createState() => _GlowingBorderState();
}

class _GlowingBorderState extends State<GlowingBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: widget.borderRadius,
                ),
                clipBehavior: Clip.hardEdge,
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: widget.colors,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(widget.borderWidth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              color: Colors.white, // Inner content background
            ),
            clipBehavior: Clip.hardEdge,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
