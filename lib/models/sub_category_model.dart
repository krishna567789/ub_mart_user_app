class SubCategoryModel {
  final String id;
  final String name;
  final String image;
  final String? categoryId;
  final bool isActive;

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.categoryId,
    this.isActive = true,
  });

  factory SubCategoryModel.fromJson(Map<String, dynamic> json) {
    String? catId;
    if (json['category'] is Map) {
      catId = json['category']['_id'];
    } else if (json['category'] is String) {
      catId = json['category'];
    }

    return SubCategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      categoryId: catId,
      isActive: json['isActive'] ?? true,
    );
  }
}
