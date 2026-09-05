import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductVariantModel _selectedVariant;
  int _activeImageIndex = 0;

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.brand ?? "Product Detail"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            if (widget.product.images.isNotEmpty)
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: widget.product.images.length,
                  onPageChanged: (idx) {
                    setState(() {
                      _activeImageIndex = idx;
                    });
                  },
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: widget.product.images[index],
                      fit: BoxFit.contain,
                      placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (c, u, e) => const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                color: Colors.grey.shade100,
                child: const Center(
                  child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                ),
              ),

            // Image Dots Indicator
            if (widget.product.images.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.product.images.length, (idx) {
                  return Container(
                    width: _activeImageIndex == idx ? 16 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
                    decoration: BoxDecoration(
                      color: _activeImageIndex == idx ? AppTheme.primary : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.product.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.product.badge!,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),

                  // Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Variants List
                  const Text(
                    "Select Unit / Variant:",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.product.variants.map((v) {
                      final isSelected = v.size == _selectedVariant.size;
                      return ChoiceChip(
                        label: Text("${v.size} - ₹${v.price.toStringAsFixed(0)}"),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryLight,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedVariant = v;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Price
                  Row(
                    children: [
                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasDiscount)
                        Text(
                          "₹${origPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  // Description
                  const Text(
                    "Product Information",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.product.description ?? "Fresh and high quality grocery item delivered directly to your doorstep.",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: qty == 0
                    ? ElevatedButton(
                        onPressed: () {
                          cart.addItem(widget.product, _selectedVariant);
                        },
                        child: const Text("ADD TO CART"),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white),
                                  onPressed: () {
                                    cart.removeItem(widget.product.id, _selectedVariant.size);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "$qty",
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: () {
                                    cart.addItem(widget.product, _selectedVariant);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CartScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                            child: const Text("GO TO CART"),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
