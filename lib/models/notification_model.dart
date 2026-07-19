class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String createdAt;
  final bool isRead;
  final String type; // Promo, OrderState, Info

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    required this.type,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: json['createdAt'] as String,
      isRead: json['isRead'] as bool? ?? false,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'createdAt': createdAt,
      'isRead': isRead,
      'type': type,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? createdAt,
    bool? isRead,
    String? type,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NotificationModel &&
            other.id == id &&
            other.title == title &&
            other.body == body &&
            other.createdAt == createdAt &&
            other.isRead == isRead &&
            other.type == type);
  }

  @override
  int get hashCode => Object.hash(id, title, body, createdAt, isRead, type);
}
