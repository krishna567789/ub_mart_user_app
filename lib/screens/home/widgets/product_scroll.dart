import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../models/product_model.dart';
import '../../../widgets/smart_image.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/custom_text.dart';
import '../../../utils/app_sizes.dart';
import '../../product_list_screen.dart';

class ProductScroll extends StatelessWidget {
  final HomepageSection section;

  const ProductScroll({super.key, required this.section});

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
            padding: EdgeInsets.fromLTRB(context.r(16), context.r(12), context.r(16), context.r(8)),
            child: CustomText(
              section.title,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),

        // Product Grid — 3 columns, using reusable ProductCard
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(4)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: context.r(12),
            crossAxisSpacing: context.r(10),
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
            margin: EdgeInsets.fromLTRB(context.r(16), context.r(8), context.r(16), context.r(16)),
            padding: EdgeInsets.symmetric(horizontal: context.r(16), vertical: context.r(12)),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(
                    displayProducts.length > 3 ? 3 : displayProducts.length,
                    (i) => Container(
                      margin: EdgeInsets.only(right: context.r(4)),
                      width: context.r(28),
                      height: context.r(28),
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
                SizedBox(width: context.r(8)),
                CustomText(
                  "See all product",
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                Icon(Icons.chevron_right, size: context.r(18), color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
