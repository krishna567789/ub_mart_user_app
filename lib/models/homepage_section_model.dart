import 'main_category_model.dart';
import 'product_model.dart';

class SectionBanner {
  final String imageUrl;
  final String linkType;
  final String? linkId;

  SectionBanner({
    required this.imageUrl,
    required this.linkType,
    this.linkId,
  });

  factory SectionBanner.fromJson(Map<String, dynamic> json) {
    return SectionBanner(
      imageUrl: json['imageUrl'] ?? '',
      linkType: json['linkType'] ?? 'NONE',
      linkId: json['linkId']?.toString(),
    );
  }
}

class HomepageSectionModel {
  final String id;
  final String type; // BANNER_SLIDER, CATEGORY_GRID, PRODUCT_SCROLL, SINGLE_BANNER, FLASH_SALE, OFFER_STRIP
  final String title;
  final int order;
  final bool isActive;
  final String bgColor;
  final List<SectionBanner> banners;
  final List<MainCategoryModel> categories;
  final List<ProductModel> products;
  final String offerText;

  HomepageSectionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.order,
    this.isActive = true,
    required this.bgColor,
    required this.banners,
    required this.categories,
    required this.products,
    required this.offerText,
  });

  factory HomepageSectionModel.fromJson(Map<String, dynamic> json) {
    final bannersList = (json['banners'] as List<dynamic>?)
            ?.map((b) => SectionBanner.fromJson(b))
            .toList() ??
        [];

    final categoriesList = (json['categoryIds'] as List<dynamic>?)
            ?.map((c) => c is Map<String, dynamic>
                ? MainCategoryModel.fromJson(c)
                : null)
            .whereType<MainCategoryModel>()
            .toList() ??
        [];

    final productsList = (json['productIds'] as List<dynamic>?)
            ?.map((p) => p is Map<String, dynamic>
                ? ProductModel.fromJson(p)
                : null)
            .whereType<ProductModel>()
            .toList() ??
        [];

    return HomepageSectionModel(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'PRODUCT_SCROLL',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      bgColor: json['bgColor'] ?? '',
      banners: bannersList,
      categories: categoriesList,
      products: productsList,
      offerText: json['offerText'] ?? '',
    );
  }
}
