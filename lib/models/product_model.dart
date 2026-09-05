class ProductVariantModel {
  final String size;
  final double price;
  final double? originalPrice;
  final int stock;

  ProductVariantModel({
    required this.size,
    required this.price,
    this.originalPrice,
    required this.stock,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      size: json['size'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice']).toDouble()
          : null,
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'price': price,
      'originalPrice': originalPrice,
      'stock': stock,
    };
  }
}

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? subCategoryId;
  final String? subCategoryName;
  final List<String> images;
  final List<ProductVariantModel> variants;
  final String? brand;
  final String? badge;
  final List<String> tags;
  final double taxPercentage;
  final bool isAvailable;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.subCategoryId,
    this.subCategoryName,
    required this.images,
    required this.variants,
    this.brand,
    this.badge,
    required this.tags,
    required this.taxPercentage,
    required this.isAvailable,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String? subCatId;
    String? subCatName;
    if (json['subCategory'] is Map) {
      subCatId = json['subCategory']['_id'];
      subCatName = json['subCategory']['name'];
    } else if (json['subCategory'] is String) {
      subCatId = json['subCategory'];
    }

    final variantsList = (json['variants'] as List<dynamic>?)
            ?.map((v) => ProductVariantModel.fromJson(v))
            .toList() ??
        [];

    final imagesList = (json['images'] as List<dynamic>?)
            ?.map((img) => img.toString())
            .toList() ??
        [];

    final tagsList = (json['tags'] as List<dynamic>?)
            ?.map((t) => t.toString())
            .toList() ??
        [];

    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      subCategoryId: subCatId,
      subCategoryName: subCatName,
      images: imagesList,
      variants: variantsList,
      brand: json['brand'],
      badge: json['badge'],
      tags: tagsList,
      taxPercentage: (json['taxPercentage'] ?? 0).toDouble(),
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  // Get active default variant or first variant
  ProductVariantModel get defaultVariant =>
      variants.isNotEmpty ? variants.first : ProductVariantModel(size: 'Default', price: 0, stock: 0);
}
