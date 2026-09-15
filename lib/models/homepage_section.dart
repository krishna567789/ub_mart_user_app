import 'product.dart';
import 'category.dart';

class BestsellerItem {
  final Category category;
  final List<Product> products;

  BestsellerItem({required this.category, required this.products});

  factory BestsellerItem.fromJson(Map<String, dynamic> json) {
    Category cat;
    try {
      final catRaw = json['categoryId'] ?? json['category'];
      if (catRaw is Map<String, dynamic>) {
        cat = Category.fromJson(catRaw);
      } else if (catRaw is Map) {
        cat = Category.fromJson(Map<String, dynamic>.from(catRaw));
      } else {
        cat = Category(
          id: catRaw?.toString() ?? '',
          name: 'Category',
          image: '',
          isActive: true,
        );
      }
    } catch (_) {
      cat = Category(id: '', name: 'Category', image: '', isActive: true);
    }

    final List<Product> parsedProducts = [];
    final rawProducts = json['productIds'] ?? json['products'];
    if (rawProducts is List) {
      for (final e in rawProducts) {
        if (e is Map<String, dynamic>) {
          try { parsedProducts.add(Product.fromJson(e)); } catch (_) {}
        } else if (e is Map) {
          try { parsedProducts.add(Product.fromJson(Map<String, dynamic>.from(e))); } catch (_) {}
        }
      }
    }

    return BestsellerItem(category: cat, products: parsedProducts);
  }
}

class HomepageBanner {
  final String imageUrl;
  final String linkType;
  final String? linkId;

  HomepageBanner({
    required this.imageUrl,
    required this.linkType,
    this.linkId,
  });

  factory HomepageBanner.fromJson(Map<String, dynamic> json) {
    return HomepageBanner(
      imageUrl: json['imageUrl'] ?? '',
      linkType: json['linkType'] ?? 'NONE',
      linkId: json['linkId'],
    );
  }
}

class HomepageSection {
  final String id;
  final String type;
  final String title;
  final int order;
  final bool isActive;
  final String bgColor;
  final List<HomepageBanner> banners;
  final List<Category> categories;
  final List<Product> products;
  final String offerText;
  final Map<String, dynamic> metadata;
  final List<BestsellerItem> bestsellerItems;

  HomepageSection({
    required this.id,
    required this.type,
    required this.title,
    required this.order,
    required this.isActive,
    required this.bgColor,
    required this.banners,
    required this.categories,
    required this.products,
    required this.offerText,
    required this.metadata,
    required this.bestsellerItems,
  });

  factory HomepageSection.fromJson(Map<String, dynamic> json) {
    // The backend populate() returns actual objects for categoryIds and productIds
    return HomepageSection(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'UNKNOWN',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      bgColor: json['bgColor'] ?? '',
      banners: (json['banners'] as List<dynamic>?)
              ?.map((e) => HomepageBanner.fromJson(e))
              .toList() ??
          [],
      categories: (json['categoryIds'] as List<dynamic>?)
              ?.map((e) => Category.fromJson(e))
              .toList() ??
          [],
      products: (json['productIds'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e))
              .toList() ??
          [],
      offerText: json['offerText'] ?? '',
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      bestsellerItems: (json['bestsellerItems'] as List<dynamic>?)
              ?.map((e) => BestsellerItem.fromJson(e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}))
              .toList() ??
          [],
    );
  }
}
