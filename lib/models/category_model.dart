import 'sub_category_model.dart';

class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String? mainCategory;
  final bool isActive;
  final List<SubCategoryModel> subCategories;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.mainCategory,
    this.isActive = true,
    this.subCategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? mainCatId;
    if (json['mainCategory'] is Map) {
      mainCatId = json['mainCategory']['_id'];
    } else if (json['mainCategory'] is String) {
      mainCatId = json['mainCategory'];
    }

    List<SubCategoryModel> subCats = [];
    if (json['subCategories'] is List) {
      subCats = (json['subCategories'] as List)
          .map((sc) => SubCategoryModel.fromJson(sc is Map ? Map<String, dynamic>.from(sc) : <String, dynamic>{}))
          .toList();
    }

    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      mainCategory: mainCatId,
      isActive: json['isActive'] ?? true,
      subCategories: subCats,
    );
  }
}
