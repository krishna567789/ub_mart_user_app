class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? link;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.link,
    this.isActive = true,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      title: json['title'] ?? '',
      link: json['link'],
      isActive: json['isActive'] ?? true,
    );
  }
}
