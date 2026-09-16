import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/smart_image.dart';
import '../widgets/veg_non_veg_badge.dart';
import '../screens/product_detail_screen.dart';
import '../utils/cart_animation_helper.dart';
import '../widgets/custom_text.dart';

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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final cart = Provider.of<CartProvider>(modalCtx);
            final primaryColor = Theme.of(context).primaryColor;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.78,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with product thumbnail, veg badge, and title
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: SmartImage(
                            imageUrl: widget.product.images.isNotEmpty
                                ? widget.product.images.first
                                : '',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (widget.product.foodType !=
                                    FoodType.none) ...[
                                  VegNonVegBadge(
                                    type: widget.product.foodType,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: CustomText(
                                    widget.product.name,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            CustomText(
                              "Select Pack Size (${widget.product.variants.length} options available)",
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),

                  // Variants List with live add / stepper
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.product.variants.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final v = widget.product.variants[index];
                        final isSelected = v.size == _selectedVariant.size;
                        final vQty = cart.getQuantity(
                          widget.product.id,
                          v.size,
                        );
                        final bool vHasDiscount =
                            (v.originalPrice ?? 0) > v.price;
                        final bool isVOutOfStock = v.stock <= 0;
                        final double savings = vHasDiscount
                            ? ((v.originalPrice ?? 0) - v.price)
                            : 0;
                        final bool isBestValue =
                            index == widget.product.variants.length - 1 &&
                            widget.product.variants.length > 1;

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedVariant = v);
                            setModalState(() {});
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade200,
                                width: isSelected ? 1.8 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Selection radio circle
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.grey.shade400,
                                      width: isSelected ? 5.5 : 1.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Variant details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CustomText(
                                            v.size,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? primaryColor
                                                : const Color(0xFF0F172A),
                                          ),
                                          if (isBestValue &&
                                              !isVOutOfStock) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const CustomText(
                                                "BEST VALUE",
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFFB45309),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          CustomText.price(
                                            "₹${v.price.toStringAsFixed(0)}",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F172A),
                                          ),
                                          if (vHasDiscount) ...[
                                            const SizedBox(width: 6),
                                            CustomText(
                                              "₹${(v.originalPrice ?? 0).toStringAsFixed(0)}",
                                              fontSize: 11,
                                              color: const Color(0xFF94A3B8),
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECFDF5),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: CustomText(
                                                "Save ₹${savings.toStringAsFixed(0)}",
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF059669),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isVOutOfStock)
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: CustomText(
                                            "Out of Stock",
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      else if (v.stock <= 5)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons
                                                    .local_fire_department_rounded,
                                                size: 11,
                                                color: Color(0xFFDC2626),
                                              ),
                                              const SizedBox(width: 2),
                                              CustomText(
                                                "Only ${v.stock} left in stock!",
                                                fontSize: 10,
                                                color: const Color(0xFFDC2626),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Action on Variant Row: ADD or Stepper or Sold Out
                                if (isVOutOfStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: const CustomText(
                                      "SOLD OUT",
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey,
                                    ),
                                  )
                                else if (vQty == 0)
                                  _AddButton(
                                    primaryColor: primaryColor,
                                    onTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() => _selectedVariant = v);
                                      cart.addItem(widget.product, v);
                                      setModalState(() {});
                                    },
                                  )
                                else
                                  _QtyController(
                                    qty: vQty,
                                    maxStock: v.stock,
                                    primaryColor: primaryColor,
                                    onAdd: () {
                                      if (vQty >= v.stock) {
                                        HapticFeedback.heavyImpact();
                                        return;
                                      }
                                      HapticFeedback.lightImpact();
                                      setState(() => _selectedVariant = v);
                                      cart.addItem(widget.product, v);
                                      setModalState(() {});
                                    },
                                    onRemove: () {
                                      HapticFeedback.lightImpact();
                                      cart.removeItem(
                                        widget.product.id,
                                        v.size,
                                      );
                                      setModalState(() {});
                                    },
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final variant = _selectedVariant;
    final int qty = cart.getQuantity(widget.product.id, variant.size);
    final bool isOutOfStock =
        variant.stock <= 0 &&
        widget.product.variants.every((v) => v.stock <= 0);
    final bool isVariantOutOfStock = variant.stock <= 0;
    final bool isLowStock =
        !isVariantOutOfStock && variant.stock > 0 && variant.stock <= 5;
    final hasDiscount = (variant.originalPrice ?? 0) > variant.price;
    final primaryColor = Theme.of(context).primaryColor;
    final favoritesProvider = Provider.of<FavoritesProvider>(context);
    final isFavorite = favoritesProvider.isFavorite(widget.product.id);

    double discountPct = 0;
    if (hasDiscount) {
      final orig = variant.originalPrice ?? 1;
      discountPct = ((orig - variant.price) / orig) * 100;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: widget.product),
        ),
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
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: SizedBox(
                    key: _cardImageKey,
                    height: 125,
                    width: double.infinity,
                    child: SmartImage(
                      imageUrl: widget.product.images.isNotEmpty
                          ? widget.product.images.first
                          : '',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Top-Left: Veg/Non-Veg Badge + Rating Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Veg / Non-Veg Indicator
                      if (widget.product.foodType != FoodType.none) ...[
                        Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: VegNonVegBadge(
                            type: widget.product.foodType,
                            size: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],

                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
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
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFEAB308),
                            ),
                            const SizedBox(width: 2),
                            CustomText(
                              widget.product.rating.toStringAsFixed(1),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Heart icon top-right
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      favoritesProvider.toggleFavorite(widget.product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey.shade600,
                        size: 17,
                      ),
                    ),
                  ),
                ),

                // OUT OF STOCK banner across bottom of image
                if (isOutOfStock || isVariantOutOfStock)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.red.shade600.withValues(alpha: 0.92),
                      child: const CustomText(
                        "OUT OF STOCK",
                        textAlign: TextAlign.center,
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                // Low stock urgency badge on bottom-left of image
                if (!isOutOfStock && isLowStock)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: const Color(0xFFFCA5A5),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            size: 11,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 2),
                          CustomText(
                            "Only ${variant.stock} left",
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ADD / Qty morphing controller overlapping image bottom-right
                if (!isOutOfStock && !isVariantOutOfStock)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: qty == 0
                          ? _AddButton(
                              key: const ValueKey('add_button'),
                              primaryColor: primaryColor,
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                CartAnimationHelper.flyToCart(
                                  context: context,
                                  imageUrl: widget.product.images.isNotEmpty
                                      ? widget.product.images.first
                                      : '',
                                  sourceKey: _cardImageKey,
                                );
                                cart.addItem(widget.product, variant);
                              },
                            )
                          : _QtyController(
                              key: const ValueKey('qty_controller'),
                              qty: qty,
                              maxStock: variant.stock,
                              primaryColor: primaryColor,
                              onAdd: () {
                                if (qty >= variant.stock) {
                                  HapticFeedback.heavyImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: CustomText(
                                        "Only ${variant.stock} units available in stock",
                                        color: Colors.white,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 1200,
                                      ),
                                      backgroundColor: Colors.red.shade700,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                HapticFeedback.lightImpact();
                                CartAnimationHelper.flyToCart(
                                  context: context,
                                  imageUrl: widget.product.images.isNotEmpty
                                      ? widget.product.images.first
                                      : '',
                                  sourceKey: _cardImageKey,
                                );
                                cart.addItem(widget.product, variant);
                              },
                              onRemove: () {
                                HapticFeedback.lightImpact();
                                cart.removeItem(
                                  widget.product.id,
                                  variant.size,
                                );
                              },
                            ),
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
                        child: CustomText(
                          variant.size,
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.product.variants.length > 1)
                        GestureDetector(
                          onTap: () => _showVariantSelector(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: primaryColor.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomText(
                                  "${widget.product.variants.length} sizes",
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 13,
                                  color: primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Product Name
                  CustomText(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.25,
                  ),
                  const SizedBox(height: 4),

                  // Delivery Time & Discount
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 13, color: primaryColor),
                      const SizedBox(width: 2),
                      const CustomText(
                        "10 mins",
                        fontSize: 10,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                      if (hasDiscount) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            "${discountPct.toStringAsFixed(0)}% OFF",
                            fontSize: 9,
                            color: const Color(0xFFEA580C),
                            fontWeight: FontWeight.w800,
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
                      CustomText(
                        "₹${variant.price.toStringAsFixed(0)}",
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 5),
                        CustomText(
                          "₹${(variant.originalPrice ?? 0).toStringAsFixed(0)}",
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                          decoration: TextDecoration.lineThrough,
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

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color primaryColor;

  const _AddButton({
    super.key,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.35),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                "ADD",
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
              SizedBox(width: 2),
              Icon(Icons.add, color: Colors.white, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}

class _QtyController extends StatelessWidget {
  final int qty;
  final int? maxStock;
  final Color primaryColor;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyController({
    super.key,
    required this.qty,
    this.maxStock,
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
            color: primaryColor.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: Icon(Icons.remove, color: Colors.white, size: 14),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: SizedBox(
              key: ValueKey<int>(qty),
              width: 18,
              child: CustomText(
                '$qty',
                textAlign: TextAlign.center,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(8),
              ),
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                child: Icon(Icons.add, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
