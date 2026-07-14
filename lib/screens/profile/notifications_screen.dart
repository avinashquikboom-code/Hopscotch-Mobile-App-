import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/notification_repository.dart';
import 'package:hopscotch/widgets/state_widgets.dart';

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
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
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
                  SnackBar(
                    content: Text(
                      'All alerts marked as read! ✔️',
                      style: TextStyle(fontSize: responsive.fontSize14),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Mark Read',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: responsive.fontSize14,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'All Caught Up!',
              description:
                  'You have no new notifications. We will alert you here when new collections drop or orders dispatch.',
            )
          : ListView.separated(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final icon = _getIconForType(notif.type);
                final color = _getColorForType(notif.type);

                return GestureDetector(
                  onTap: () {
                    notifier.markAsRead(notif.id);
                  },
                  child: Container(
                    padding: EdgeInsets.all(
                      responsive.spacing(AppTheme.spaceL),
                    ),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? Colors.white
                          : color.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      border: Border.all(
                        color: notif.isRead
                            ? AppTheme.borderColor
                            : color.withValues(alpha: 0.2),
                        width: notif.isRead ? 1 : 1.5,
                      ),
                      boxShadow: notif.isRead ? null : AppTheme.softShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(responsive.spacing(10)),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: responsive.iconSize(22),
                          ),
                        ),
                        SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: notif.isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        fontSize: responsive.fontSize14,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: responsive.spacing(8),
                                      height: responsive.spacing(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: responsive.spacing(4)),
                              Text(
                                notif.body,
                                style: responsive.bodyMedium.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceS),
                              ),
                              Text(
                                notif.createdAt,
                                style: TextStyle(
                                  color: AppTheme.textLightColor,
                                  fontSize: responsive.fontSize10,
                                ),
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
