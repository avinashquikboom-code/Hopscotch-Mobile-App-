import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/notification_model.dart';

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  NotificationNotifier() : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate API fetch delay
    await Future.delayed(const Duration(milliseconds: 300));
    state = DummyData.dummyNotifications.map((e) => NotificationModel.fromJson(e)).toList();
  }

  void markAsRead(String notificationId) {
    state = [
      for (final notif in state)
        if (notif.id == notificationId) notif.copyWith(isRead: true) else notif
    ];
  }

  void markAllAsRead() {
    state = [
      for (final notif in state) notif.copyWith(isRead: true)
    ];
  }

  void clearNotifications() {
    state = [];
  }

  int get unreadCount {
    return state.where((element) => !element.isRead).length;
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, List<NotificationModel>>((ref) {
  return NotificationNotifier();
});
