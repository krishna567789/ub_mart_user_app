import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AnimatedVoiceSearch extends StatefulWidget {
  const AnimatedVoiceSearch({super.key});

  @override
  State<AnimatedVoiceSearch> createState() => _AnimatedVoiceSearchState();
}

class _AnimatedVoiceSearchState extends State<AnimatedVoiceSearch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primary.withOpacity(0.1 + (_controller.value * 0.1)),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(Icons.mic, color: AppTheme.primary, size: 20),
          ),
        );
      },
    );
  }
}
