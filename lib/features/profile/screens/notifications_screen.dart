import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:hopscotch/features/profile/repositories/notification_repository.dart';
import '../../../core/widgets/state_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'promo':
        return Icons.local_offer_outlined;
      case 'orderstate':
        return Icons.local_shipping_outlined;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'promo':
        return AppTheme.accentColor;
      case 'orderstate':
        return AppTheme.secondaryColor;
      case 'info':
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTIFICATIONS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                notifier.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All alerts marked as read! ✔️'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Mark Read', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'All Caught Up!',
              description: 'You have no new notifications. We will alert you here when new collections drop or orders dispatch.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spaceXL),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spaceM),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final icon = _getIconForType(notif.type);
                final color = _getColorForType(notif.type);

                return GestureDetector(
                  onTap: () {
                    notifier.markAsRead(notif.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spaceL),
                    decoration: BoxDecoration(
                      color: notif.isRead ? Colors.white : color.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: notif.isRead ? AppTheme.borderColor : color.withOpacity(0.2),
                        width: notif.isRead ? 1 : 1.5,
                      ),
                      boxShadow: notif.isRead ? null : AppTheme.softShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon circle
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 22),
                        ),
                        const SizedBox(width: AppTheme.spaceL),
                        // Text body
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 14,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondaryColor,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              Text(
                                notif.createdAt,
                                style: const TextStyle(color: AppTheme.textLightColor, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
