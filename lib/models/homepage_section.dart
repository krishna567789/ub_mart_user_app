import 'product.dart';
import 'category.dart';

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
    );
  }
}
