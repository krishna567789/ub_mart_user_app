class Category {
  final String id;
  final String name;
  final String? description;
  final String image;
  final bool isActive;
  final String? storeId;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.image,
    required this.isActive,
    this.storeId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      image: json['image'] ?? 'https://via.placeholder.com/150',
      isActive: json['isActive'] ?? true,
      storeId: json['storeId'],
    );
  }
}
