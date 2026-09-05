import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late ProductVariantModel _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.defaultVariant;
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final int qty = cart.getQuantity(widget.product.id, _selectedVariant.size);

    final double price = _selectedVariant.price;
    final double? origPrice = _selectedVariant.originalPrice;
    final bool hasDiscount = origPrice != null && origPrice > price;
    final int discountPercent = hasDiscount
        ? (((origPrice - price) / origPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image & Discount Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    color: Colors.grey.shade50,
                    child: widget.product.images.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.product.images.first,
                            fit: BoxFit.contain,
                            placeholder: (ctx, url) => const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                            errorWidget: (ctx, url, err) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 40),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "$discountPercent% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (widget.product.badge != null && widget.product.badge!.isNotEmpty)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Variant selector dropdown if multiple variants
                  if (widget.product.variants.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ProductVariantModel>(
                          value: _selectedVariant,
                          isDense: true,
                          style: const TextStyle(fontSize: 11, color: Colors.black87),
                          items: widget.product.variants.map((v) {
                            return DropdownMenuItem<ProductVariantModel>(
                              value: v,
                              child: Text(v.size),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedVariant = val;
                              });
                            }
                          },
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _selectedVariant.size,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ),

                  // Price and Add / Qty controller
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (hasDiscount)
                            Text(
                              "₹${origPrice.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),

                      // Add / Quantity Controller
                      qty == 0
                          ? InkWell(
                              onTap: () {
                                cart.addItem(widget.product, _selectedVariant);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryLight,
                                  border: Border.all(color: AppTheme.primary),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "ADD",
                                  style: TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      cart.removeItem(widget.product.id, _selectedVariant.size);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.remove, color: Colors.white, size: 16),
                                    ),
                                  ),
                                  Text(
                                    "$qty",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      cart.addItem(widget.product, _selectedVariant);
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      child: Icon(Icons.add, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
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
    );
  }
}
