import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../models/homepage_section.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../product_detail_screen.dart';

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
          .map<ProductVariantModel>((v) => ProductVariantModel(
                size: v.size,
                price: v.price,
                originalPrice: v.originalPrice,
                stock: v.stock,
              ))
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

    final cart = Provider.of<CartProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: section.products.length,
            itemBuilder: (context, index) {
              final product = section.products[index];
              final productModel = _toProductModel(product);
              final defaultVariant = productModel.defaultVariant;

              final int qty = cart.getQuantity(productModel.id, defaultVariant.size);
              final hasDiscount = product.maxPrice > product.minPrice;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: productModel),
                    ),
                  );
                },
                child: Container(
                  width: 145,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CachedNetworkImage(
                                imageUrl: product.primaryImage,
                                fit: BoxFit.contain,
                                height: 100,
                                width: double.infinity,
                                errorWidget: (context, url, error) => const Icon(
                                  Icons.image_not_supported,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          if (hasDiscount)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'OFFER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                defaultVariant.size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (hasDiscount)
                                        Text(
                                          '₹${product.maxPrice.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        '₹${product.minPrice.toStringAsFixed(0)}',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                      ),
                                    ],
                                  ),

                                  // Add / Quantity Controller
                                  qty == 0
                                      ? Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () {
                                              cart.addItem(productModel, defaultVariant);
                                            },
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                ),
                                                borderRadius: BorderRadius.circular(6),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(context).primaryColor.withOpacity(0.05),
                                                    Theme.of(context).primaryColor.withOpacity(0.15),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Text(
                                                'ADD',
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () {
                                                  cart.removeItem(productModel.id, defaultVariant.size);
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  child: Icon(Icons.remove, color: Colors.white, size: 14),
                                                ),
                                              ),
                                              Text(
                                                '$qty',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () {
                                                  cart.addItem(productModel, defaultVariant);
                                                },
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  child: Icon(Icons.add, color: Colors.white, size: 14),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
