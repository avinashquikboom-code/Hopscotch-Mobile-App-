import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/widgets/state_widgets.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  String _selectedFilter = 'ALL'; // ALL, PROCESSING, SHIPPED, DELIVERED, CANCELLED

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'delivered':
        return AppTheme.successColor;
      case 'processing':
      case 'confirmed':
      case 'pending':
        return AppTheme.accentColor;
      case 'shipped':
        return AppTheme.secondaryColor;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return AppTheme.primaryColor;
    }
  }

  bool _isCancellable(String status) {
    final lower = status.toLowerCase().trim();
    if (lower.isEmpty) return true;
    return lower != 'cancelled' &&
        lower != 'delivered' &&
        lower != 'returned' &&
        lower != 'shipped' &&
        lower != 'out_for_delivery';
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    if (_selectedFilter == 'ALL') return orders;
    return orders.where((o) {
      final st = o.status.toUpperCase().trim();
      switch (_selectedFilter) {
        case 'PROCESSING':
          return st == 'PENDING' ||
              st == 'PROCESSING' ||
              st == 'CONFIRMED' ||
              st == 'PAID' ||
              st == 'CREATED' ||
              st == 'ORDER_PLACED' ||
              st == 'PLACED';
        case 'SHIPPED':
          return st == 'SHIPPED' || st == 'OUT_FOR_DELIVERY' || st == 'IN_TRANSIT';
        case 'DELIVERED':
          return st == 'DELIVERED' || st == 'COMPLETED';
        case 'CANCELLED':
          return st == 'CANCELLED' || st == 'REFUNDED';
        default:
          return st == _selectedFilter;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Row - Improved Design
          Container(
            height: 60,
            color: Colors.transparent,
            padding: EdgeInsets.fromLTRB(
              responsive.spacing(AppTheme.spaceL),
              responsive.spacing(AppTheme.spaceM),
              responsive.spacing(AppTheme.spaceL),
              responsive.spacing(AppTheme.spaceM),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFilterChip('ALL', 'All Orders', colorScheme, responsive),
                SizedBox(width: responsive.spacing(8)),
                _buildFilterChip('PROCESSING', 'Processing', colorScheme, responsive),
                SizedBox(width: responsive.spacing(8)),
                _buildFilterChip('SHIPPED', 'Shipped', colorScheme, responsive),
                SizedBox(width: responsive.spacing(8)),
                _buildFilterChip('DELIVERED', 'Delivered', colorScheme, responsive),
                SizedBox(width: responsive.spacing(8)),
                _buildFilterChip('CANCELLED', 'Cancelled', colorScheme, responsive),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load order history', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (allOrders) {
                final orders = _filterOrders(allOrders);

                if (allOrders.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Orders Placed Yet',
                    description: 'Your handcrafted order history and tracking info will appear here once you place an order.',
                    buttonText: 'Explore Catalog',
                    onButtonPressed: () => context.go('/'),
                  );
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_off_outlined, size: 48, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No $_selectedFilter orders found',
                          style: TextStyle(
                            fontSize: responsive.fontSize14,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
                  child: ListView.separated(
                    padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusColor = _getStatusColor(order.status);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          safeNavigate(context, '/order-detail', extra: order);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? colorScheme.surface.withValues(alpha: 0.8) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.12),
                              width: 1.5,
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row - Order ID & Status
                              Padding(
                                padding: EdgeInsets.all(responsive.spacing(14)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(responsive.spacing(8)),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.local_mall_outlined,
                                            size: 18,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        SizedBox(width: responsive.spacing(10)),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order #${order.id}',
                                              style: TextStyle(
                                                fontSize: responsive.fontSize13,
                                                fontWeight: FontWeight.w800,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            SizedBox(height: responsive.spacing(2)),
                                            Text(
                                              order.orderDate,
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: responsive.spacing(10),
                                        vertical: responsive.spacing(6),
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: statusColor,
                                            ),
                                          ),
                                          SizedBox(width: responsive.spacing(6)),
                                          Text(
                                            order.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: responsive.fontSize10,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Items Preview
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  responsive.spacing(14),
                                  0,
                                  responsive.spacing(14),
                                  responsive.spacing(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 70,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: order.items.length,
                                        itemBuilder: (context, idx) {
                                          final item = order.items[idx];
                                          final resolvedUrl = AppUrls.resolveUrl(item.product.imageUrl);

                                          return Container(
                                            margin: EdgeInsets.only(right: responsive.spacing(10)),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: resolvedUrl.isNotEmpty
                                                      ? Image.network(
                                                          resolvedUrl,
                                                          width: 70,
                                                          height: 70,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            width: 70,
                                                            height: 70,
                                                            decoration: BoxDecoration(
                                                              color: colorScheme.outline.withValues(alpha: 0.1),
                                                              borderRadius: BorderRadius.circular(12),
                                                            ),
                                                            child: Icon(
                                                              Icons.image_not_supported_outlined,
                                                              size: 24,
                                                              color: colorScheme.onSurface.withValues(alpha: 0.3),
                                                            ),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 70,
                                                          height: 70,
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.outline.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          child: Icon(
                                                            Icons.image_not_supported_outlined,
                                                            size: 24,
                                                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                                                          ),
                                                        ),
                                                ),
                                                if (item.quantity > 1)
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: responsive.spacing(6),
                                                        vertical: responsive.spacing(3),
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.primaryColor,
                                                        borderRadius: const BorderRadius.only(
                                                          topLeft: Radius.circular(8),
                                                          bottomRight: Radius.circular(12),
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black.withValues(alpha: 0.2),
                                                            blurRadius: 4,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        'x${item.quantity}',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: responsive.fontSize10,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing(10)),
                                    Text(
                                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize12,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(alpha: isDark ? 0.1 : 0.08),
                              ),

                              // Footer - Amount & Action
                              Padding(
                                padding: EdgeInsets.all(responsive.spacing(14)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize10,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        SizedBox(height: responsive.spacing(4)),
                                        Text(
                                          currency.formatPrice(order.totalAmount),
                                          style: TextStyle(
                                            fontSize: responsive.fontSize16,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (_isCancellable(order.status))
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: responsive.spacing(8),
                                              vertical: responsive.spacing(4),
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.errorColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Cancellable',
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.errorColor,
                                              ),
                                            ),
                                          ),
                                        if (_isCancellable(order.status)) SizedBox(width: responsive.spacing(8)),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: responsive.spacing(12),
                                            vertical: responsive.spacing(6),
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'View',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                              SizedBox(width: responsive.spacing(4)),
                                              Icon(
                                                Icons.arrow_forward_ios_rounded,
                                                size: responsive.iconSize(12),
                                                color: AppTheme.primaryColor,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, ColorScheme colorScheme, ResponsiveText responsive) {
    final isSelected = _selectedFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedFilter = value);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(14),
            vertical: responsive.spacing(8),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark
                    ? colorScheme.surface.withValues(alpha: 0.8)
                    : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : AppTheme.primaryColor.withValues(alpha: 0.15)),
              width: 1.5,
            ),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDark ? colorScheme.onSurface : AppTheme.primaryColor),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: responsive.fontSize11,
            ),
          ),
        ),
      ),
    );
  }
}
