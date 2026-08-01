class BannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? subtitle;
  final String? link;
  final String type;
  final String position;
  final DateTime? endDate;
  final int order;
  final bool isActive;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.link,
    this.type = 'home',
    this.position = 'HOME',
    this.endDate,
    required this.order,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? json['image_url']?.toString() ?? json['image']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? json['description']?.toString(),
      link: json['link']?.toString() ?? json['targetUrl']?.toString(),
      type: json['type']?.toString() ?? 'home',
      position: json['position']?.toString() ?? 'HOME',
      endDate: json['endDate'] != null || json['end_date'] != null
          ? DateTime.tryParse(json['endDate']?.toString() ?? json['end_date']?.toString() ?? '')
          : null,
      order: json['sortOrder'] as int? ?? json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'link': link,
      'type': type,
      'position': position,
      'endDate': endDate?.toIso8601String(),
      'order': order,
      'isActive': isActive,
    };
  }
}
