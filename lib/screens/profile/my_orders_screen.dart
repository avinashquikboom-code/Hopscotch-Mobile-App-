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
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'MY ORDERS',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: () => ref.read(orderProvider.notifier).fetchOrders(),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Row
          Container(
            height: 52,
            color: colorScheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildFilterChip('ALL', 'All Orders', colorScheme),
                _buildFilterChip('PROCESSING', 'Processing', colorScheme),
                _buildFilterChip('SHIPPED', 'Shipped', colorScheme),
                _buildFilterChip('DELIVERED', 'Delivered', colorScheme),
                _buildFilterChip('CANCELLED', 'Cancelled', colorScheme),
              ],
            ),
          ),
          const Divider(height: 1),

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
                            color: isDark ? colorScheme.surface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.local_mall_outlined, size: 18, color: AppTheme.primaryColor),
                                        const SizedBox(width: 8),
                                        Text(
                                          '#${order.id}',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize14,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                                          const SizedBox(width: 6),
                                          Text(
                                            order.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: responsive.fontSize10,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Items Preview Row
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 64,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: order.items.length,
                                        itemBuilder: (context, idx) {
                                          final item = order.items[idx];
                                          final resolvedUrl = AppUrls.resolveUrl(item.product.imageUrl);

                                          return Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            child: Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: resolvedUrl.isNotEmpty
                                                      ? Image.network(
                                                          resolvedUrl,
                                                          width: 64,
                                                          height: 64,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (_, __, ___) => Container(
                                                            width: 64,
                                                            height: 64,
                                                            color: colorScheme.outline.withValues(alpha: 0.1),
                                                            child: const Icon(Icons.image_not_supported_outlined, size: 20),
                                                          ),
                                                        )
                                                      : Container(
                                                          width: 64,
                                                          height: 64,
                                                          color: colorScheme.outline.withValues(alpha: 0.1),
                                                          child: const Icon(Icons.image_not_supported_outlined, size: 20),
                                                        ),
                                                ),
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withValues(alpha: 0.75),
                                                      borderRadius: const BorderRadius.only(
                                                        topLeft: Radius.circular(6),
                                                        bottomRight: Radius.circular(10),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'x${item.quantity}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
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
                                    const SizedBox(height: 12),
                                    Text(
                                      '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'} • Placed on ${order.orderDate}',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize12,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // Footer Row
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'TOTAL AMOUNT',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize10,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
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
                                        if (_isCancellable(order.status)) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: Colors.red.shade200),
                                            ),
                                            child: Text(
                                              'Cancellable',
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          'View Details',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize12,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 12,
                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
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

  Widget _buildFilterChip(String value, String label, ColorScheme colorScheme) {
    final isSelected = _selectedFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = value;
            });
          }
        },
        selectedColor: AppTheme.primaryColor,
        backgroundColor: colorScheme.surface,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.2),
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
