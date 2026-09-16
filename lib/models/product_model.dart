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

class ReviewModel {
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return ReviewModel(
      userName: json['userName'] ?? 'Verified Buyer',
      rating: (json['rating'] ?? 5).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
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
  final double rating;
  final int reviewCount;
  final List<ReviewModel> reviews;

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
    this.rating = 4.6,
    this.reviewCount = 28,
    this.reviews = const [],
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

    final reviewsList = (json['reviews'] as List<dynamic>?)
            ?.map((r) => ReviewModel.fromJson(r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{}))
            .toList() ??
        [];

    double prodRating = (json['rating'] != null) ? (json['rating']).toDouble() : 4.6;
    if (prodRating == 0) prodRating = 4.6;

    int prodReviewCount = (json['reviewCount'] != null)
        ? (json['reviewCount'] as num).toInt()
        : (reviewsList.isNotEmpty ? reviewsList.length : 28);

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
      rating: prodRating,
      reviewCount: prodReviewCount,
      reviews: reviewsList,
    );
  }

  // Get active default variant or first variant
  ProductVariantModel get defaultVariant =>
      variants.isNotEmpty ? variants.first : ProductVariantModel(size: 'Default', price: 0, stock: 0);

  /// Automatically resolves whether the product is Veg, Non-Veg, Egg, or Non-Food.
  FoodType get foodType {
    final lowerName = name.toLowerCase();
    final lowerSub = (subCategoryName ?? '').toLowerCase();
    final lowerDesc = (description ?? '').toLowerCase();
    final tagsStr = tags.join(" ").toLowerCase();
    final allText = '$lowerName $lowerSub $lowerDesc $tagsStr';

    // 1. Non-food detection (cleaning, personal care, electronics, pooja items, etc.)
    if (allText.contains('detergent') ||
        allText.contains('cleaner') ||
        allText.contains('shampoo') ||
        allText.contains('soap') ||
        allText.contains('harpic') ||
        allText.contains('vim') ||
        allText.contains('colgate') ||
        allText.contains('toothpaste') ||
        allText.contains('toothbrush') ||
        allText.contains('battery') ||
        allText.contains('diaper') ||
        allText.contains('sanitary') ||
        allText.contains('perfume') ||
        allText.contains('deodorant') ||
        allText.contains('lotion') ||
        (allText.contains('cream') &&
            !allText.contains('ice cream') &&
            !allText.contains('milk cream') &&
            !allText.contains('malai')) ||
        allText.contains('face wash') ||
        allText.contains('scrub') ||
        allText.contains('tissue') ||
        allText.contains('wipe') ||
        allText.contains('broom') ||
        allText.contains('mop') ||
        allText.contains('foil') ||
        allText.contains('scrubber') ||
        allText.contains('pooja') ||
        allText.contains('agarbatti') ||
        allText.contains('dhoop') ||
        allText.contains('bulb') ||
        allText.contains('utensil') ||
        allText.contains('bottle') ||
        allText.contains('plastic')) {
      return FoodType.none;
    }

    // 2. Non-Veg detection
    if (allText.contains('non-veg') ||
        allText.contains('nonveg') ||
        allText.contains('chicken') ||
        allText.contains('mutton') ||
        allText.contains('meat') ||
        allText.contains('fish') ||
        allText.contains('prawn') ||
        allText.contains('seafood') ||
        allText.contains('pork') ||
        allText.contains('beef')) {
      return FoodType.nonVeg;
    }

    // 3. Egg detection
    if (allText.contains('egg') && !allText.contains('eggless')) {
      return FoodType.egg;
    }

    // 4. Defaults to Vegetarian for grocery & kitchen items
    return FoodType.veg;
  }
}

enum FoodType {
  veg,
  nonVeg,
  egg,
  none,
}

