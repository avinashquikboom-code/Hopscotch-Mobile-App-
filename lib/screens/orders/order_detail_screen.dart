import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/repositories/notification_repository.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel? order;
  final String? orderId;

  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
  });

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderModel? _detailedOrder;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    final targetId = widget.order?.id ?? widget.orderId;
    if (targetId == null || targetId.isEmpty) return;

    // Use passed order initial value if available
    if (widget.order != null && widget.order!.shippingAddress.isNotEmpty) {
      _detailedOrder = widget.order;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ordersApi = ref.read(ordersApiProvider);
      final response = await ordersApi.getOrderById(targetId);
      final body = response.data;

      Map<String, dynamic>? orderData;
      if (body is Map<String, dynamic>) {
        if (body['order'] is Map<String, dynamic>) {
          orderData = body['order'] as Map<String, dynamic>;
        } else if (body['data'] is Map<String, dynamic>) {
          final innerData = body['data'] as Map<String, dynamic>;
          if (innerData['order'] is Map<String, dynamic>) {
            orderData = innerData['order'] as Map<String, dynamic>;
          } else {
            orderData = innerData;
          }
        } else {
          orderData = body;
        }
      }

      if (orderData != null && mounted) {
        final parsed = OrderModel.fromJson(orderData);
        setState(() {
          _detailedOrder = parsed;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep existing widget.order if API fails, otherwise note error
          if (_detailedOrder == null && widget.order != null) {
            _detailedOrder = widget.order;
          } else if (_detailedOrder == null) {
            _errorMessage = 'Could not load order details';
          }
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'delivered':
        return AppTheme.successColor;
      case 'processing':
      case 'confirmed':
        return AppTheme.accentColor;
      case 'shipped':
        return AppTheme.secondaryColor;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return AppTheme.textSecondaryColor;
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

  int _getStatusStep(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      case 'cancelled':
        return -1;
      default:
        return 1;
    }
  }

  void _confirmCancelOrder(BuildContext context, OrderModel order) {
    String selectedReason = 'Changed my mind';
    final customReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Colors.red.shade600, size: 24),
                  const SizedBox(width: 8),
                  const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please select a reason for cancelling Order #${order.id}:',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Changed my mind',
                      'Ordered by mistake',
                      'Found a lower price elsewhere',
                      'Delivery taking too long',
                      'Other'
                    ].map((reason) {
                      return RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedReason = val;
                            });
                          }
                        },
                      );
                    }),
                    if (selectedReason == 'Other') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customReasonController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Enter reason details...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text('KEEP ORDER'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final finalReason = selectedReason == 'Other'
                        ? (customReasonController.text.trim().isNotEmpty ? customReasonController.text.trim() : 'Other')
                        : selectedReason;

                    Navigator.of(dialogCtx).pop();

                    try {
                      await ref.read(orderProvider.notifier).cancelOrder(
                            order.id,
                            reason: finalReason,
                          );
                      ref.read(notificationProvider.notifier).addNotification(
                        title: 'Order Cancelled ❌',
                        body: 'Order #${order.id} was cancelled ($finalReason).',
                        type: 'order',
                      );

                      _fetchOrderDetails();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Order #${order.id} cancelled successfully'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to cancel order: $e'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('CONFIRM CANCEL'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemThumbnail(ProductModel product, ColorScheme colorScheme) {
    String rawUrl = product.imageUrl;
    if (rawUrl.isEmpty && product.additionalImages.isNotEmpty) {
      rawUrl = product.additionalImages.first;
    }
    final resolvedUrl = AppUrls.resolveUrl(rawUrl);

    if (resolvedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          resolvedUrl,
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(colorScheme),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 68,
              height: 68,
              color: colorScheme.outline.withValues(alpha: 0.08),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallbackThumbnail(colorScheme);
  }

  Widget _buildFallbackThumbnail(ColorScheme colorScheme) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Resolve order from local state, passed prop, or store
    OrderModel? activeOrder = _detailedOrder ?? widget.order;
    if (activeOrder == null && widget.orderId != null && ordersAsync is AsyncData) {
      final list = ordersAsync.value ?? [];
      try {
        activeOrder = list.firstWhere((o) => o.id == widget.orderId);
      } catch (_) {}
    }

    if (activeOrder == null && _isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('ORDER DETAILS')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (activeOrder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ORDER DETAILS')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Order details unavailable'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _fetchOrderDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = activeOrder;
    final statusColor = _getStatusColor(order.status);
    final currentStep = _getStatusStep(order.status);
    final isCancellable = _isCancellable(order.status);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'ORDER DETAILS',
          style: TextStyle(
            fontSize: responsive.fontSize16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my-orders');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _fetchOrderDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, size: 22),
            onPressed: () => safeNavigate(context, '/help-center'),
            tooltip: 'Support',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrderDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loading Indicator bar if refreshing
              if (_isLoading) ...[
                const LinearProgressIndicator(minHeight: 3),
                const SizedBox(height: 12),
              ],

              // Order ID & Status Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORDER NUMBER',
                            style: TextStyle(
                              fontSize: responsive.fontSize10,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '#${order.id}',
                            style: TextStyle(
                              fontSize: responsive.fontSize18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placed on ${order.orderDate}',
                            style: TextStyle(
                              fontSize: responsive.fontSize11,
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: responsive.fontSize11,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Order Status Stepper
              if (currentStep > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER STATUS TRACKER',
                        style: TextStyle(
                          fontSize: responsive.fontSize11,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStepNode('Placed', 1, currentStep, colorScheme, responsive),
                          _buildStepLine(1, currentStep, colorScheme),
                          _buildStepNode('Processing', 2, currentStep, colorScheme, responsive),
                          _buildStepLine(2, currentStep, colorScheme),
                          _buildStepNode('Shipped', 3, currentStep, colorScheme, responsive),
                          _buildStepLine(3, currentStep, colorScheme),
                          _buildStepNode('Delivered', 4, currentStep, colorScheme, responsive),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Delivery Address Section Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'DELIVERY ADDRESS',
                          style: TextStyle(
                            fontSize: responsive.fontSize11,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      order.shippingAddress.trim().isNotEmpty
                          ? order.shippingAddress
                          : 'Standard Delivery Address',
                      style: TextStyle(
                        fontSize: responsive.fontSize13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.85),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tracking Reference Card
              if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping_outlined, color: AppTheme.primaryColor, size: 22),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRACKING NUMBER',
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                order.trackingNumber!,
                                style: TextStyle(
                                  fontSize: responsive.fontSize14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: order.trackingNumber!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tracking number copied! 📋'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Order Items List Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ORDER ITEMS (${order.items.length})',
                      style: TextStyle(
                        fontSize: responsive.fontSize11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, idx) {
                        final item = order.items[idx];

                        return GestureDetector(
                          onTap: () => safeNavigate(context, '/product/${item.product.id}'),
                          child: Row(
                            children: [
                              _buildItemThumbnail(item.product, colorScheme),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize14,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (item.selectedSize != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: colorScheme.outline.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Size: ${item.selectedSize}',
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize12,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currency.formatPrice(item.product.price * item.quantity),
                                style: TextStyle(
                                  fontSize: responsive.fontSize14,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Payment Summary Breakdown Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT SUMMARY',
                      style: TextStyle(
                        fontSize: responsive.fontSize11,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Payment Method', order.paymentMethod.toUpperCase(), responsive, colorScheme),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Shipping', 'FREE', responsive, colorScheme),
                    const Divider(height: 20),
                    _buildSummaryRow('Total Paid', currency.formatPrice(order.totalAmount), responsive, colorScheme, isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // Pinned Cancel Order Bottom Action Bar
      bottomNavigationBar: isCancellable
          ? Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
                border: Border(
                  top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.12)),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _confirmCancelOrder(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  'CANCEL THIS ORDER',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStepNode(String title, int stepNum, int currentStep, ColorScheme colorScheme, ResponsiveText responsive) {
    final isDone = currentStep >= stepNum;
    final isCurrent = currentStep == stepNum;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.15),
              border: Border.all(
                color: isCurrent ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text(
                      '$stepNum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: responsive.fontSize10,
              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
              color: isDone ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int stepNum, int currentStep, ColorScheme colorScheme) {
    final isDone = currentStep > stepNum;
    return Container(
      width: 20,
      height: 2,
      color: isDone ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  Widget _buildSummaryRow(String label, String value, ResponsiveText responsive, ColorScheme colorScheme, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize14 : responsive.fontSize12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize16 : responsive.fontSize13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold,
            color: isTotal ? AppTheme.primaryColor : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
