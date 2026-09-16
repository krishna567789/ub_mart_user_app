import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../widgets/custom_text.dart';

class CuratedMoods extends StatelessWidget {
  const CuratedMoods({super.key});

  @override
  Widget build(BuildContext context) {
    final moods = [
      {
        "title": "Late Night 🌙",
        "subtitle": "Munchies",
        "color": const Color(0xFFE9D5FF),
        "textColor": const Color(0xFF7E22CE),
        "img":
            "https://images.unsplash.com/photo-1590846406792-0adc7f138fbc?w=400&q=80",
      },
      {
        "title": "Pre-Workout ⚡️",
        "subtitle": "High Protein",
        "color": const Color(0xFFBBF7D0),
        "textColor": const Color(0xFF15803D),
        "img":
            "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&q=80",
      },
      {
        "title": "Rainy Day ☕️",
        "subtitle": "Chai & Dip",
        "color": const Color(0xFFFED7AA),
        "textColor": const Color(0xFFB45309),
        "img":
            "https://images.unsplash.com/photo-1515823662972-da6a2b4d3002?w=400&q=80",
      },
      {
        "title": "Chef's Pantry 👨‍🍳",
        "subtitle": "Artisanal",
        "color": const Color(0xFFFEF08A),
        "textColor": const Color(0xFFA16207),
        "img":
            "https://images.unsplash.com/photo-1556910103-1c02745a8e8f?w=400&q=80",
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomText(
                  "Curated Moods & Occasions",
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
                const SizedBox(height: 2),
                CustomText(
                  "Vibe-matched grocery baskets dispatched instantly",
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: moods.length,
              itemBuilder: (context, index) {
                final mood = moods[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(mood["img"] as String),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: mood["color"] as Color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mood["subtitle"] as String,
                                style: TextStyle(
                                  color: mood["textColor"] as Color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mood["title"] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
