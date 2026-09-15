import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';
import '../utils/app_sizes.dart';

class CartBottomBar extends StatelessWidget {
  final VoidCallback onTap;
  const CartBottomBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    if (cart.itemCount == 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.r(16),
        vertical: context.r(10),
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(context.r(16))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "${cart.itemCount} ${cart.itemCount == 1 ? 'ITEM' : 'ITEMS'}",
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                CustomText(
                  "₹${cart.grandTotal.toStringAsFixed(0)}",
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  const CustomText(
                    "View Cart",
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(width: context.r(6)),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: context.r(16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
