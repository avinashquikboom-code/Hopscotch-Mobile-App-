import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/widgets/state_widgets.dart';
import 'package:hopscotch/providers/currency_provider.dart';

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppTheme.successColor;
      case 'processing':
        return AppTheme.accentColor;
      case 'shipped':
        return AppTheme.secondaryColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ORDER HISTORY',
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
      ),
      body: orders.isEmpty
          ? EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Orders Placed Yet',
              description:
                  'When you purchase elite designs, your handcrafted order tracking records will appear here.',
              buttonText: 'Browse Catalog',
              onButtonPressed: () => context.go('/'),
            )
          : ListView.separated(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
              itemCount: orders.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
              itemBuilder: (context, index) {
                final order = orders[index];
                final statusColor = _getStatusColor(order.status);

                return Container(
                  padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: TextStyle(
                                  fontSize: responsive.fontSize16,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(2)),
                              Text(
                                order.orderDate,
                                style: TextStyle(
                                  color: AppTheme.textLightColor,
                                  fontSize: responsive.fontSize11,
                                ),
                              ),
                            ],
                          ),
                          // Status Badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(10),
                              vertical: responsive.spacing(6),
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: responsive.fontSize10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: responsive.spacing(AppTheme.spaceXL)),

                      // Horizontal item images
                      SizedBox(
                        height: responsive.spacing(60),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: order.items.length,
                          itemBuilder: (context, index) {
                            final item = order.items[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: responsive.spacing(AppTheme.spaceM),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS,
                                ),
                                child: Image.network(
                                  item.product.imageUrl,
                                  width: responsive.spacing(60),
                                  height: responsive.spacing(60),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: responsive.spacing(60),
                                    height: responsive.spacing(60),
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.05),
                                    child: Icon(
                                      Icons.image_not_supported_rounded,
                                      size: responsive.iconSize(20),
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(height: responsive.spacing(AppTheme.spaceXL)),

                      // Footer Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL AMOUNT',
                                style: TextStyle(
                                  color: AppTheme.textLightColor,
                                  fontSize: responsive.fontSize10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(2)),
                              Text(
                                currency.formatPrice(order.totalAmount),
                                style: TextStyle(
                                  fontSize: responsive.fontSize20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (order.trackingNumber != null)
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Courier reference copied: ${order.trackingNumber} 📋',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize14,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(12),
                                  vertical: responsive.spacing(8),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                size: responsive.iconSize(14),
                              ),
                              label: Text(
                                'Track',
                                style: TextStyle(
                                  fontSize: responsive.fontSize12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
