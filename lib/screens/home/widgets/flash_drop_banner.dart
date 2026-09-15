import 'package:flutter/material.dart';

import '../../../models/homepage_section.dart';
import '../../../widgets/smart_image.dart';
import '../../../widgets/glowing_border.dart';
import '../../../theme/app_theme.dart';

class FlashDropBanner extends StatelessWidget {
  final HomepageSection section;

  const FlashDropBanner({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlowingBorder(
        borderRadius: BorderRadius.circular(20),
        borderWidth: 2.5,
        colors: const [
          Color(0xFFF43F5E), // Rose
          Color(0xFFF97316), // Orange
          Color(0xFFF43F5E), // Rose
        ],
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1118),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Background Image with Dark Overlay
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.65),
                      BlendMode.darken,
                    ),
                    child: SmartImage(
                      imageUrl: section.metadata['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF374151),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            section.metadata['timerString'] ??
                                "00H : 00M : 00S",
                            style: TextStyle(
                              color: AppTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      section.metadata['titlePart1'] ?? "",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.accent, AppTheme.primary],
                      ).createShader(bounds),
                      child: Text(
                        section.metadata['titlePart2'] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      section.metadata['titlePart3'] ?? "",
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      section.metadata['description'] ?? "",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Floating "SAVE ₹140" Pill
              Positioned(
                right: 16,
                top: 16,
                child: Transform.rotate(
                  angle: -0.05, // Slight tilt like in the design
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF43F5E), Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "SAVE ₹${section.metadata['saveAmount'] ?? 0}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ), // Closes Container
                ), // Closes Transform.rotate
              ), // Closes Positioned
            ],
          ), // closes Stack
        ), // closes child: Container
      ), // closes child: GlowingBorder
    ); // closes return Container
  }
}
