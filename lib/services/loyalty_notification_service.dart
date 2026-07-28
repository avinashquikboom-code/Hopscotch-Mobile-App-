import 'package:flutter/foundation.dart';

class LoyaltyNotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  LoyaltyNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });
}

class LoyaltyNotificationService {
  static final LoyaltyNotificationService _instance = LoyaltyNotificationService._internal();

  factory LoyaltyNotificationService() => _instance;

  LoyaltyNotificationService._internal();

  final List<LoyaltyNotificationItem> _notifications = [];

  List<LoyaltyNotificationItem> get notifications => List.unmodifiable(_notifications);

  void showNotification(String title, String body) {
    debugPrint('[NOTIFICATION] $title: $body');
    _notifications.insert(
      0,
      LoyaltyNotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = LoyaltyNotificationItem(
        id: _notifications[i].id,
        title: _notifications[i].title,
        body: _notifications[i].body,
        timestamp: _notifications[i].timestamp,
        isRead: true,
      );
    }
  }
}
