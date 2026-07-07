class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? link;
  final int order;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.link,
    required this.order,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      link: json['link']?.toString(),
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'order': order,
      'isActive': isActive,
    };
  }
}
