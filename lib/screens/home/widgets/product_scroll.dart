import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../models/product_model.dart';
import '../../../widgets/smart_image.dart';
import '../../../widgets/product_card.dart';
import '../../product_list_screen.dart';

class ProductScroll extends StatelessWidget {
  final HomepageSection section;

  const ProductScroll({Key? key, required this.section}) : super(key: key);

  ProductModel _toProductModel(dynamic p) {
    return ProductModel(
      id: p.id,
      name: p.name,
      description: p.description,
      subCategoryId: p.subCategory,
      images: p.images,
      variants: p.variants
          .map<ProductVariantModel>(
            (v) => ProductVariantModel(
              size: v.size,
              price: v.price,
              originalPrice: v.originalPrice,
              stock: v.stock,
            ),
          )
          .toList(),
      brand: p.brand,
      badge: p.badge,
      tags: p.tags,
      taxPercentage: p.taxPercentage,
      isAvailable: p.isAvailable,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();

    final displayProducts = section.products.take(6).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = Theme.of(context).textTheme.titleLarge?.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              section.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: titleColor,
              ),
            ),
          ),

        // Product Grid — 3 columns, using reusable ProductCard
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12.0,
            crossAxisSpacing: 10.0,
            childAspectRatio: 0.48,
          ),
          itemCount: displayProducts.length,
          itemBuilder: (context, index) {
            final productModel = _toProductModel(displayProducts[index]);
            return ProductCard(product: productModel);
          },
        ),

        // "See all product >" banner at bottom
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductListScreen(title: section.title),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(
                    displayProducts.length > 3 ? 3 : displayProducts.length,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipOval(
                        child: SmartImage(
                          imageUrl: displayProducts[i].primaryImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "See all product",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
