import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/smart_image.dart';

class CartAnimationHelper {
  // GlobalKey for the floating cart box so the flying drop targets it directly
  static final GlobalKey cartTargetKey = GlobalKey();

  // ValueNotifier to trigger a bounce/pulse animation on the cart bar when item drops
  static final ValueNotifier<int> cartBounceNotifier = ValueNotifier<int>(0);

  /// Flies an image from [sourceKey] or [fallbackStartOffset] to the floating cart bar
  static void flyToCart({
    required BuildContext context,
    required String? imageUrl,
    GlobalKey? sourceKey,
    Offset? fallbackStartOffset,
  }) {
    try {
      final overlay = Overlay.of(context);

      Offset start = fallbackStartOffset ?? const Offset(100, 300);
      if (sourceKey != null && sourceKey.currentContext != null) {
        final renderBox = sourceKey.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          start = renderBox.localToGlobal(renderBox.size.center(Offset.zero));
        }
      }

      // Find target position (avatars section in cart bar)
      final screenSize = MediaQuery.of(context).size;
      Offset target = Offset(60, screenSize.height - 85);
      if (cartTargetKey.currentContext != null) {
        final renderBox = cartTargetKey.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          target = renderBox.localToGlobal(const Offset(40, 45));
        }
      }

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) => _FlyingImageWidget(
          start: start,
          target: target,
          imageUrl: imageUrl ?? '',
          onComplete: () {
            entry.remove();
            cartBounceNotifier.value++;
            HapticFeedback.mediumImpact();
          },
        ),
      );

      overlay.insert(entry);
    } catch (e) {
      debugPrint('CartAnimation error: $e');
    }
  }
}

class _FlyingImageWidget extends StatefulWidget {
  final Offset start;
  final Offset target;
  final String imageUrl;
  final VoidCallback onComplete;

  const _FlyingImageWidget({
    required this.start,
    required this.target,
    required this.imageUrl,
    required this.onComplete,
  });

  @override
  State<_FlyingImageWidget> createState() => _FlyingImageWidgetState();
}

class _FlyingImageWidgetState extends State<_FlyingImageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final t = _animation.value;

        // Parabolic arc for realistic physical trajectory
        final double arcHeight = -55.0 * math.sin(t * math.pi);
        final double currentX = widget.start.dx + (widget.target.dx - widget.start.dx) * t;
        final double currentY = widget.start.dy + (widget.target.dy - widget.start.dy) * t + arcHeight;

        // Size scales down from 54px to 24px as it approaches the cart box
        final double size = 54.0 - (30.0 * t);

        // Rotation for organic feel
        final double rotation = math.sin(t * math.pi * 2) * 0.2;

        // Subtle fade right at the very end as it lands inside the box
        final double opacity = (1.0 - (t > 0.9 ? (t - 0.9) / 0.1 : 0.0)).clamp(0.0, 1.0);

        final primaryColor = Theme.of(context).primaryColor;

        return Positioned(
          left: currentX - (size / 2),
          top: currentY - (size / 2),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.55 * (1.0 - t)),
                      blurRadius: 14,
                      spreadRadius: 3,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: primaryColor,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: SmartImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
