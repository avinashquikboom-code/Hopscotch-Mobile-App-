import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_service.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../../core/dummy_data/dummy_data.dart';
import '../models/notification_model.dart';

class NotificationNotifier extends StateNotifier<List<NotificationModel>> {
  final ApiService _apiService;

  NotificationNotifier(this._apiService) : super([]) {
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _apiService.get('/api/notifications');
      if (response.statusCode == 200) {
        final data = response.data;
        final List? rawList = data is Map ? data['data'] : data;
        if (rawList != null) {
          state = rawList.map((e) {
            return NotificationModel(
              id: e['id']?.toString() ?? '',
              title: e['title']?.toString() ?? '',
              body: e['message']?.toString() ?? e['body']?.toString() ?? '',
              createdAt: e['sentAt']?.toString() ?? e['createdAt']?.toString() ?? '',
              isRead: e['isRead'] as bool? ?? false,
              type: e['type']?.toString() ?? 'general',
            );
          }).toList();
          return;
        }
      }
    } catch (e) {
      print('[NotificationNotifier] Error loading notifications: $e');
    }

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
  final apiService = ref.watch(apiServiceProvider);
  return NotificationNotifier(apiService);
});
