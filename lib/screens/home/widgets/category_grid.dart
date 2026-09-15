import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../widgets/smart_image.dart';
import '../../product_list_screen.dart';
import '../../../widgets/custom_text.dart';

class CategoryGrid extends StatelessWidget {
  final HomepageSection section;

  const CategoryGrid({Key? key, required this.section}) : super(key: key);

  // Soft pastel background colors similar to the design
  static const List<Color> _cardColors = [
    Color(0xFFE8F5E9), // Light Green
    Color(0xFFFFEBEE), // Light Pink/Red
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFFFF3E0), // Light Orange
    Color(0xFFFFF8E1), // Light Yellow
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFFBE9E7), // Light Peach
    Color(0xFFEDE7F6), // Light Indigo
  ];

  @override
  Widget build(BuildContext context) {
    if (section.categories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
          ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // 4 columns like Blinkit
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 12.0,
            childAspectRatio: 0.75, // Adjust for image + text height
          ),
          itemCount: section.categories.length,
          itemBuilder: (context, index) {
            final category = section.categories[index];
            final color = _cardColors[index % _cardColors.length];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      title: category.name,
                      categoryId: category.id,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image container
                  AspectRatio(
                    aspectRatio: 1.0, // Square
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.5), // Very light soft pastel
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Center(
                        child: SmartImage(
                          imageUrl: category.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Expanded(
                    child: CustomText(
                      category.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
