class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String? mainCategory;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.mainCategory,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    String? mainCatId;
    if (json['mainCategory'] is Map) {
      mainCatId = json['mainCategory']['_id'];
    } else if (json['mainCategory'] is String) {
      mainCatId = json['mainCategory'];
    }

    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      mainCategory: mainCatId,
      isActive: json['isActive'] ?? true,
    );
  }
}
