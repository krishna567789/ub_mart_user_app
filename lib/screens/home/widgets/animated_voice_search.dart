import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/voice_search_modal.dart';
import '../../search/product_search_screen.dart';

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

  void _openVoiceModal() {
    VoiceSearchModal.show(
      context,
      onQuerySelected: (query) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductSearchScreen(initialQuery: query),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openVoiceModal,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(
                alpha: 0.1 + (_controller.value * 0.1),
              ),
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(Icons.mic_rounded, color: AppTheme.primary, size: 20),
            ),
          );
        },
      ),
    );
  }
}
