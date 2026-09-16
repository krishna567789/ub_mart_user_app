import 'package:flutter/material.dart';
import '../models/product_model.dart';

/// Production-standard FSSAI Indian Veg / Non-Veg / Egg indicator badge.
class VegNonVegBadge extends StatelessWidget {
  final FoodType type;
  final double size;
  final bool showLabel;

  const VegNonVegBadge({
    super.key,
    required this.type,
    this.size = 12,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    if (type == FoodType.none) {
      return const SizedBox.shrink();
    }

    Color color;
    String label;

    switch (type) {
      case FoodType.veg:
        color = const Color(0xFF16A34A); // Green
        label = "VEG";
        break;
      case FoodType.nonVeg:
        color = const Color(0xFFDC2626); // Red
        label = "NON-VEG";
        break;
      case FoodType.egg:
        color = const Color(0xFFD97706); // Amber/Yellow
        label = "EGG";
        break;
      case FoodType.none:
        return const SizedBox.shrink();
    }

    final double dotSize = size * 0.44;

    Widget badge = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: size > 16 ? 1.6 : 1.2),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: type == FoodType.nonVeg
          ? CustomPaint(
              size: Size(dotSize * 1.1, dotSize * 1.1),
              painter: _TrianglePainter(color: color),
            )
          : Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
    );

    if (!showLabel) {
      return badge;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: size * 0.75,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
