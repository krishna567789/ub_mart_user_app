class ProductVariant {
  final String size;
  final double price;
  final double? originalPrice;
  final int stock;

  ProductVariant({
    required this.size,
    required this.price,
    this.originalPrice,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      size: json['size'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null ? (json['originalPrice']).toDouble() : null,
      stock: json['stock'] ?? 0,
    );
  }
}


class Product {
  final String id;
  final String name;
  final String? description;
  final String subCategory;
  final List<String> images;
  final List<ProductVariant> variants;
  final String? brand;
  final String? badge;
  final List<String> tags;
  final double taxPercentage;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.subCategory,
    required this.images,
    required this.variants,
    this.brand,
    this.badge,
    required this.tags,
    required this.taxPercentage,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      subCategory: json['subCategory'] is String ? json['subCategory'] : (json['subCategory']?['_id'] ?? ''),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      variants: (json['variants'] as List<dynamic>?)?.map((e) => ProductVariant.fromJson(e)).toList() ?? [],
      brand: json['brand'],
      badge: json['badge'],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // Helper method to get primary image
  String get primaryImage => images.isNotEmpty ? images.first : 'https://via.placeholder.com/150';
  
  // Helper to get minimum price among variants
  double get minPrice {
    if (variants.isEmpty) return 0.0;
    double min = variants.first.price;
    for (var v in variants) {
      if (v.price < min) min = v.price;
    }
    return min;
  }

  // Helper to get maximum original price (for discounts)
  double get maxPrice {
    if (variants.isEmpty) return 0.0;
    double max = variants.first.originalPrice ?? variants.first.price;
    for (var v in variants) {
      double p = v.originalPrice ?? v.price;
      if (p > max) max = p;
    }
    return max;
  }
}
