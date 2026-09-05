class MainCategoryModel {
  final String id;
  final String name;
  final String image;
  final bool isActive;

  MainCategoryModel({
    required this.id,
    required this.name,
    required this.image,
    this.isActive = true,
  });

  factory MainCategoryModel.fromJson(Map<String, dynamic> json) {
    return MainCategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
}
