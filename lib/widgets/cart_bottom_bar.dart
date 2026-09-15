import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';
import '../widgets/smart_image.dart';
import '../utils/app_sizes.dart';

class CartBottomBar extends StatelessWidget {
  final VoidCallback onTap;
  const CartBottomBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    if (cart.itemCount == 0) return const SizedBox.shrink();

    final primaryColor = Theme.of(context).primaryColor;
    final displayedItems = cart.itemList.take(3).toList();
    final totalSavings = cart.totalSavings;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.r(12),
            context.r(4),
            context.r(12),
            context.r(10),
          ),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // Sleek dark slate
                borderRadius: BorderRadius.circular(context.r(18)),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top delivery & savings bar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.r(14),
                      vertical: context.r(6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(context.r(17)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: context.r(7),
                              height: context.r(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.r(7)),
                            const CustomText(
                              "Locked: 8–10 Min Guaranteed Delivery",
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ],
                        ),
                        if (totalSavings > 0)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.r(7),
                              vertical: context.r(2),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(context.r(6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                                SizedBox(width: context.r(3)),
                                CustomText(
                                  "Saved ₹${totalSavings.toStringAsFixed(0)}",
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF92400E),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom cart info row
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      context.r(12),
                      context.r(8),
                      context.r(12),
                      context.r(10),
                    ),
                    child: Row(
                      children: [
                        // Product image thumbnails (circular)
                        if (displayedItems.isNotEmpty) ...[
                          SizedBox(
                            width: displayedItems.length * context.r(26.0) + context.r(6),
                            height: context.r(36),
                            child: Stack(
                              children: List.generate(displayedItems.length, (i) {
                                final item = displayedItems[i];
                                return Positioned(
                                  left: i * context.r(26.0),
                                  child: Container(
                                    width: context.r(36),
                                    height: context.r(36),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: primaryColor.withValues(alpha: 0.6),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: SmartImage(
                                        imageUrl: item.product.images.isNotEmpty
                                            ? item.product.images.first
                                            : '',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          SizedBox(width: context.r(10)),
                        ],

                        // Price & item count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  CustomText(
                                    "₹${cart.grandTotal.toStringAsFixed(0)}",
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                  if (cart.totalMrp > cart.itemTotal) ...[
                                    SizedBox(width: context.r(6)),
                                    CustomText(
                                      "₹${cart.totalMrp.toStringAsFixed(0)}",
                                      color: Colors.white38,
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: Colors.white38,
                                    ),
                                  ],
                                ],
                              ),
                              CustomText(
                                "${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''} • Ready",
                                color: Colors.white60,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ),

                        // View Cart Button
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.r(14),
                            vertical: context.r(9),
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(context.r(12)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CustomText(
                                "View Cart",
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              SizedBox(width: context.r(4)),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: context.r(14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
