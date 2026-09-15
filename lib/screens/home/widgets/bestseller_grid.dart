import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../models/product.dart';
import '../../../widgets/smart_image.dart';
import '../../product_list_screen.dart';

class BestsellerGrid extends StatelessWidget {
  final HomepageSection section;

  const BestsellerGrid({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (section.bestsellerItems.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: titleColor,
                letterSpacing: -0.3,
              ),
            ),
          ),
        // Horizontal scroll of category cards
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: section.bestsellerItems.length,
            itemBuilder: (context, index) {
              final item = section.bestsellerItems[index];
              return _CategoryCard(item: item);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final BestsellerItem item;
  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final products = item.products.take(4).toList();
    final hasProducts = products.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final gridBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final emptySlotBg = isDark ? const Color(0xFF26334D) : Colors.grey.shade100;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              title: item.category.name,
              categoryId: item.category.id,
            ),
          ),
        );
      },
      child: Container(
        width: 168,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 2×2 Product Image Grid OR category image fallback
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: hasProducts
                    ? _ProductGrid(
                        products: products,
                        gridBg: gridBg,
                        emptySlotBg: emptySlotBg,
                      )
                    : _CategoryImageFallback(
                        imageUrl: item.category.image,
                        bgColor: gridBg,
                      ),
              ),
            ),
            // Category Name at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Text(
                item.category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 2×2 product image grid
class _ProductGrid extends StatelessWidget {
  final List<Product> products;
  final Color gridBg;
  final Color emptySlotBg;

  const _ProductGrid({
    required this.products,
    required this.gridBg,
    required this.emptySlotBg,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        childAspectRatio: 1.0,
      ),
      itemCount: 4,
      itemBuilder: (context, i) {
        if (i < products.length) {
          final img = products[i].primaryImage;
          return Container(
            decoration: BoxDecoration(
              color: gridBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SmartImage(imageUrl: img, fit: BoxFit.contain),
            ),
          );
        }
        // Empty slot
        return Container(
          decoration: BoxDecoration(
            color: emptySlotBg,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

// Fallback when no products assigned yet
class _CategoryImageFallback extends StatelessWidget {
  final String imageUrl;
  final Color bgColor;

  const _CategoryImageFallback({required this.imageUrl, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SmartImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
