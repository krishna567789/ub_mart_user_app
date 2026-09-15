import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/smart_image.dart';
import '../screens/product_detail_screen.dart';
import '../utils/cart_animation_helper.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late ProductVariantModel _selectedVariant;
  final GlobalKey _cardImageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.defaultVariant;
  }

  void _showVariantSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cart = Provider.of<CartProvider>(ctx);
        final primaryColor = Theme.of(context).primaryColor;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Choose Variant / Pack Size",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...widget.product.variants.map((v) {
                final isSelected = v.size == _selectedVariant.size;
                final vQty = cart.getQuantity(widget.product.id, v.size);
                final bool vHasDiscount = (v.originalPrice ?? 0) > v.price;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.08) : Colors.white,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.size,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? primaryColor : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  "₹${v.price.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (vHasDiscount) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    "₹${(v.originalPrice ?? 0).toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      vQty == 0
                          ? ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                CartAnimationHelper.flyToCart(
                                  context: context,
                                  imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                                );
                                setState(() => _selectedVariant = v);
                                cart.addItem(widget.product, v);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text("ADD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          : _QtyController(
                              qty: vQty,
                              primaryColor: primaryColor,
                              onAdd: () {
                                HapticFeedback.lightImpact();
                                cart.addItem(widget.product, v);
                              },
                              onRemove: () {
                                HapticFeedback.lightImpact();
                                cart.removeItem(widget.product.id, v.size);
                              },
                            ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final variant = _selectedVariant;
    final int qty = cart.getQuantity(widget.product.id, variant.size);
    final bool isOutOfStock = variant.stock <= 0 && widget.product.variants.every((v) => v.stock <= 0);
    final bool hasDiscount = (variant.originalPrice ?? 0) > variant.price;
    final primaryColor = Theme.of(context).primaryColor;

    double discountPct = 0;
    if (hasDiscount) {
      final orig = variant.originalPrice ?? 1;
      discountPct = ((orig - variant.price) / orig) * 100;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: widget.product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                // Product Image fills full width with rounded top corners
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: SizedBox(
                    key: _cardImageKey,
                    height: 125,
                    width: double.infinity,
                    child: SmartImage(
                      imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Rating Badge on top-left
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 13, color: Color(0xFFEAB308)),
                        const SizedBox(width: 2),
                        Text(
                          widget.product.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Heart icon top-right
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.favorite_border, color: Colors.grey, size: 18),
                ),

                // OUT OF STOCK banner at bottom of image
                if (isOutOfStock)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.red.shade400.withValues(alpha: 0.92),
                      child: const Text(
                        "OUT OF STOCK",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                // ADD / Qty controller overlapping image bottom-right
                if (!isOutOfStock)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: qty == 0
                        ? _AddButton(
                            primaryColor: primaryColor,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              CartAnimationHelper.flyToCart(
                                context: context,
                                imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                                sourceKey: _cardImageKey,
                              );
                              cart.addItem(widget.product, variant);
                            },
                          )
                        : _QtyController(
                            qty: qty,
                            primaryColor: primaryColor,
                            onAdd: () {
                              HapticFeedback.lightImpact();
                              CartAnimationHelper.flyToCart(
                                context: context,
                                imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                                sourceKey: _cardImageKey,
                              );
                              cart.addItem(widget.product, variant);
                            },
                            onRemove: () {
                              HapticFeedback.lightImpact();
                              cart.removeItem(widget.product.id, variant.size);
                            },
                          ),
                  ),
              ],
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Weight/Size with optional Multi-variant chooser
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          variant.size,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.product.variants.length > 1)
                        GestureDetector(
                          onTap: () => _showVariantSelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "${widget.product.variants.length} options ▾",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Product Name
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.25),
                  ),
                  const SizedBox(height: 4),

                  // Delivery Time & Discount
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 13, color: primaryColor),
                      const SizedBox(width: 2),
                      const Text("10 mins", style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      if (hasDiscount) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            "${discountPct.toStringAsFixed(0)}% OFF",
                            style: const TextStyle(fontSize: 9, color: Color(0xFFEA580C), fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Price + MRP
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "₹${variant.price.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 5),
                        Text(
                          "₹${(variant.originalPrice ?? 0).toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
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

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color primaryColor;

  const _AddButton({required this.onTap, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: const Text(
          "ADD",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _QtyController extends StatelessWidget {
  final int qty;
  final Color primaryColor;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyController({
    required this.qty,
    required this.primaryColor,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Icon(Icons.remove, color: Colors.white, size: 14),
            ),
          ),
          Text(
            '$qty',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
          ),
          GestureDetector(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              child: Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
