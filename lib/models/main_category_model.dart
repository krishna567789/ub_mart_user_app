import 'category_model.dart';

class MainCategoryModel {
  final String id;
  final String name;
  final String image;
  final bool isActive;
  final List<CategoryModel> categories;

  MainCategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.isActive = true,
    this.categories = const [],
  });

  factory MainCategoryModel.fromJson(Map<String, dynamic> json) {
    List<CategoryModel> cats = [];
    if (json['categories'] is List) {
      cats = (json['categories'] as List)
          .map((c) => CategoryModel.fromJson(c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{}))
          .toList();
    }

    return MainCategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? true,
      categories: cats,
    );
  }
}
