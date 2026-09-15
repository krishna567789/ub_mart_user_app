import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../widgets/smart_image.dart';
import '../../../widgets/glowing_border.dart';
import '../../../widgets/custom_text.dart';
import '../../../utils/app_sizes.dart';

class LightningDeals extends StatelessWidget {
  final HomepageSection section;

  const LightningDeals({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.products.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(vertical: context.r(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.r(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(context.r(4)),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(context.r(4)),
                      ),
                      child: Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: context.r(14),
                      ),
                    ),
                    SizedBox(width: context.r(8)),
                    CustomText(
                      "Lightning Deals",
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.r(8),
                    vertical: context.r(4),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: CustomText(
                    section.metadata['timerText'] ?? "Ends soon",
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.r(16)),
          SizedBox(
            height: context.r(280),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              itemCount: section.products.length,
              itemBuilder: (context, index) {
                final product = section.products[index];
                final variant = product.variants.first;
                return Container(
                  width: context.r(140),
                  margin: EdgeInsets.only(right: context.r(12)),
                  child: GlowingBorder(
                    borderWidth: 2.0,
                    borderRadius: BorderRadius.circular(context.r(16)),
                    colors: const [
                      Color(0xFFFFD700), // Gold
                      Color(0xFFFF8C00), // Dark Orange
                      Color(0xFFFFD700),
                    ],
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(context.r(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image & Badges
                          Stack(
                            children: [
                              Container(
                                height: context.r(120),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(context.r(16)),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(context.r(16)),
                                  ),
                                  child: SmartImage(
                                    imageUrl: product.images.isNotEmpty
                                        ? product.images.first
                                        : '',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: context.r(8),
                                left: context.r(8),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.r(6),
                                    vertical: context.r(2),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(context.r(4)),
                                  ),
                                  child: CustomText(
                                    product.badge ?? "DEAL",
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: context.r(8),
                                right: context.r(8),
                                child: Icon(
                                  Icons.favorite_border,
                                  color: Colors.grey,
                                  size: context.r(16),
                                ),
                              ),
                            ],
                          ),
                          // Content
                          Padding(
                            padding: EdgeInsets.all(context.r(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.r(4),
                                        vertical: context.r(2),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(context.r(4)),
                                      ),
                                      child: CustomText(
                                        product.description ?? "Organic",
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    if (variant.stock < 20)
                                      CustomText(
                                        "${variant.stock} Left",
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      )
                                    else
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.green,
                                            size: context.r(10),
                                          ),
                                          const CustomText(
                                            " 4.8",
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                SizedBox(height: context.r(6)),
                                CustomText(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  height: 1.2,
                                ),
                                SizedBox(height: context.r(4)),
                                CustomText(
                                  variant.size,
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: context.r(8)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CustomText(
                                          "₹${variant.price}",
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                        if (variant.originalPrice != null)
                                          CustomText(
                                            "₹${variant.originalPrice}",
                                            fontSize: 9,
                                            color: Colors.grey,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.r(8),
                                        vertical: context.r(6),
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0C831F),
                                        borderRadius: BorderRadius.circular(context.r(8)),
                                      ),
                                      child: const CustomText(
                                        "+ ADD",
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
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
