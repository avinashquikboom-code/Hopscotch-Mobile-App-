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

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  OrderModel? _detailedOrder;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchOrderDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    final targetId = widget.order?.id ?? widget.orderId;
    if (targetId == null || targetId.isEmpty) return;

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
          orderData = innerData['order'] is Map<String, dynamic>
              ? innerData['order'] as Map<String, dynamic>
              : innerData;
        } else {
          orderData = body;
        }
      }

      if (orderData != null && mounted) {
        setState(() {
          _detailedOrder = OrderModel.fromJson(orderData!);
          _isLoading = false;
        });
        _animController.forward(from: 0);
      } else if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward(from: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_detailedOrder == null && widget.order != null) {
            _detailedOrder = widget.order;
          } else if (_detailedOrder == null) {
            _errorMessage = 'Could not load order details';
          }
        });
        _animController.forward(from: 0);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().trim()) {
      case 'delivered':
        return const Color(0xFF10B981);
      case 'processing':
      case 'confirmed':
        return const Color(0xFF6366F1);
      case 'shipped':
      case 'out_for_delivery':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'pending':
      case 'pending_payment':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase().trim()) {
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'processing':
      case 'confirmed':
        return Icons.inventory_2_rounded;
      case 'shipped':
      case 'out_for_delivery':
        return Icons.local_shipping_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'pending':
      case 'pending_payment':
        return Icons.access_time_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  bool _isCancellable(String status) {
    final lower = status.toLowerCase().trim();
    return lower != 'cancelled' &&
        lower != 'delivered' &&
        lower != 'returned' &&
        lower != 'shipped' &&
        lower != 'out_for_delivery';
  }

  int _getStatusStep(String status) {
    switch (status.toLowerCase().trim()) {
      case 'pending':
      case 'pending_payment':
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
      case 'out_for_delivery':
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cancel_outlined,
                            color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Cancel Order',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Why are you cancelling Order #${order.id}?',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'Changed my mind',
                    'Ordered by mistake',
                    'Found a lower price elsewhere',
                    'Delivery taking too long',
                    'Other'
                  ].map((reason) {
                    final selected = selectedReason == reason;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedReason = reason),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryColor
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.3),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: selected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(reason,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (selectedReason == 'Other') ...[
                    const SizedBox(height: 4),
                    TextField(
                      controller: customReasonController,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe your reason...',
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Keep Order',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          onPressed: () async {
                            final finalReason = selectedReason == 'Other'
                                ? (customReasonController.text
                                        .trim()
                                        .isNotEmpty
                                    ? customReasonController.text.trim()
                                    : 'Other')
                                : selectedReason;
                            Navigator.of(sheetCtx).pop();
                            try {
                              await ref
                                  .read(orderProvider.notifier)
                                  .cancelOrder(order.id, reason: finalReason);
                              ref
                                  .read(notificationProvider.notifier)
                                  .addNotification(
                                    title: 'Order Cancelled ❌',
                                    body:
                                        'Order #${order.id} was cancelled ($finalReason).',
                                    type: 'order',
                                  );
                              _fetchOrderDetails();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Order #${order.id} cancelled'),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Failed to cancel: $e'),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Confirm Cancel',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          resolvedUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackThumbnail(colorScheme),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.08),
            AppTheme.primaryColor.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Icon(Icons.shopping_bag_outlined,
          color: AppTheme.primaryColor, size: 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    OrderModel? activeOrder = _detailedOrder ?? widget.order;
    if (activeOrder == null &&
        widget.orderId != null &&
        ordersAsync is AsyncData) {
      final list = ordersAsync.value ?? [];
      try {
        activeOrder = list.firstWhere((o) => o.id == widget.orderId);
      } catch (_) {}
    }

    // ── Loading state ─────────────────────────────────────────────────────
    if (activeOrder == null && _isLoading) {
      return Scaffold(
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
        appBar: _buildAppBar(context, colorScheme, responsive),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text('Loading order details...',
                  style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: responsive.fontSize13)),
            ],
          ),
        ),
      );
    }

    // ── Error state ───────────────────────────────────────────────────────
    if (activeOrder == null) {
      return Scaffold(
        backgroundColor:
            isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
        appBar: _buildAppBar(context, colorScheme, responsive),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.receipt_long_outlined,
                      size: 48, color: colorScheme.error),
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage ?? 'Order details unavailable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: responsive.fontSize14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _fetchOrderDetails,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = activeOrder;
    final statusColor = _getStatusColor(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final currentStep = _getStatusStep(order.status);
    final isCancellable = _isCancellable(order.status);
    final isCancelled = order.status.toLowerCase().trim() == 'cancelled';

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF1F5F9),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.white, size: 20),
            ),
            onPressed: _fetchOrderDetails,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.headset_mic_outlined,
                  color: Colors.white, size: 20),
            ),
            onPressed: () => safeNavigate(context, '/help-center'),
            tooltip: 'Support',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _fetchOrderDetails,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Hero Header ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCancelled
                          ? [
                              const Color(0xFFEF4444),
                              const Color(0xFFDC2626),
                            ]
                          : [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.75),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          20, 8, 20, screenWidth * 0.12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  order.status
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Order number
                          Text(
                            '#${order.id}',
                            style: TextStyle(
                              fontSize: clampDouble(
                                  responsive.fontSize24, 20, 32),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Placed on ${order.orderDate}',
                            style: TextStyle(
                              fontSize: responsive.fontSize12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Quick info row
                          Row(
                            children: [
                              _buildHeroInfoChip(
                                icon: Icons.inventory_2_outlined,
                                label: '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                              ),
                              const SizedBox(width: 10),
                              _buildHeroInfoChip(
                                icon: Icons.payments_outlined,
                                label: currency.formatPrice(order.totalAmount),
                              ),
                              const SizedBox(width: 10),
                              _buildHeroInfoChip(
                                icon: Icons.credit_card_rounded,
                                label: order.paymentMethod
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Content cards (overlapping header) ─────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -(screenWidth * 0.08)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Loading bar
                        if (_isLoading) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // ── Status Tracker ────────────────────────────
                        if (!isCancelled && currentStep > 0) ...[
                          _buildCard(
                            isDark: isDark,
                            colorScheme: colorScheme,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionHeader(
                                  icon: Icons.timeline_rounded,
                                  label: 'ORDER TRACKER',
                                  colorScheme: colorScheme,
                                  responsive: responsive,
                                ),
                                const SizedBox(height: 20),
                                _buildTimeline(
                                    currentStep, colorScheme, responsive),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Cancelled banner ──────────────────────────
                        if (isCancelled) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.cancel_rounded,
                                      color: Colors.red, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Cancelled',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'This order has been cancelled. Refund will be processed within 3–5 business days.',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize12,
                                          color: Colors.red.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Tracking Number ───────────────────────────
                        if (order.trackingNumber != null &&
                            order.trackingNumber!.isNotEmpty) ...[
                          _buildCard(
                            isDark: isDark,
                            colorScheme: colorScheme,
                            accentColor: AppTheme.primaryColor,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                      Icons.local_shipping_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'TRACKING NUMBER',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize10,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primaryColor,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        order.trackingNumber!,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize14,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(
                                        text: order.trackingNumber!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Tracking number copied! 📋'),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            AppTheme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy_rounded,
                                            size: 13,
                                            color: AppTheme.primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Copy',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Delivery Address ──────────────────────────
                        _buildCard(
                          isDark: isDark,
                          colorScheme: colorScheme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                icon: Icons.location_on_rounded,
                                label: 'DELIVERY ADDRESS',
                                colorScheme: colorScheme,
                                responsive: responsive,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colorScheme.outline
                                      .withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: colorScheme.outline
                                          .withValues(alpha: 0.1)),
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.home_rounded,
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.6),
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        order.shippingAddress.trim()
                                                .isNotEmpty
                                            ? order.shippingAddress
                                            : 'Standard Delivery Address',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize13,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.85),
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Order Items ───────────────────────────────
                        _buildCard(
                          isDark: isDark,
                          colorScheme: colorScheme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                icon: Icons.shopping_bag_rounded,
                                label:
                                    'ORDER ITEMS (${order.items.length})',
                                colorScheme: colorScheme,
                                responsive: responsive,
                              ),
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics:
                                    const NeverScrollableScrollPhysics(),
                                itemCount: order.items.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 24,
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.1)),
                                itemBuilder: (context, idx) {
                                  final item = order.items[idx];
                                  return GestureDetector(
                                    onTap: () => safeNavigate(context,
                                        '/product/${item.product.id}'),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildItemThumbnail(
                                            item.product, colorScheme),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.product.title,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize:
                                                      responsive.fontSize14,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color:
                                                      colorScheme.onSurface,
                                                  height: 1.3,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6,
                                                children: [
                                                  if (item.selectedSize !=
                                                      null)
                                                    _buildChip(
                                                        'Size: ${item.selectedSize}',
                                                        colorScheme),
                                                  _buildChip(
                                                      'Qty: ${item.quantity}',
                                                      colorScheme),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                currency.formatPrice(
                                                    item.product.price *
                                                        item.quantity),
                                                style: TextStyle(
                                                  fontSize:
                                                      responsive.fontSize15,
                                                  fontWeight:
                                                      FontWeight.w900,
                                                  color:
                                                      AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Payment Summary ───────────────────────────
                        _buildCard(
                          isDark: isDark,
                          colorScheme: colorScheme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                icon: Icons.receipt_long_rounded,
                                label: 'PAYMENT SUMMARY',
                                colorScheme: colorScheme,
                                responsive: responsive,
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow(
                                label: 'Subtotal',
                                value: currency.formatPrice(
                                    order.totalAmount > 99
                                        ? order.totalAmount - 0
                                        : order.totalAmount),
                                responsive: responsive,
                                colorScheme: colorScheme,
                              ),
                              const SizedBox(height: 10),
                              _buildSummaryRow(
                                label: 'Shipping',
                                value: order.totalAmount > 1000
                                    ? 'FREE'
                                    : currency.formatPrice(99),
                                responsive: responsive,
                                colorScheme: colorScheme,
                                valueColor: const Color(0xFF10B981),
                              ),
                              const SizedBox(height: 10),
                              _buildSummaryRow(
                                label: 'Payment Method',
                                value: order.paymentMethod
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                responsive: responsive,
                                colorScheme: colorScheme,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                child: Divider(
                                    color: colorScheme.outline
                                        .withValues(alpha: 0.15),
                                    height: 1),
                              ),
                              // Total row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Paid',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize15,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryColor,
                                          AppTheme.primaryColor
                                              .withValues(alpha: 0.8),
                                        ],
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      currency
                                          .formatPrice(order.totalAmount),
                                      style: TextStyle(
                                        fontSize: responsive.fontSize16,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                            height: isCancellable
                                ? 100
                                : MediaQuery.of(context).padding.bottom +
                                    24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom Cancel Bar ─────────────────────────────────────────────
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
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => safeNavigate(context, '/help-center'),
                      icon: const Icon(Icons.headset_mic_outlined, size: 18),
                      label: const Text('Support'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                            color: colorScheme.outline
                                .withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmCancelOrder(context, order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon:
                          const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(
                        'Cancel Order',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: responsive.fontSize14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // ── Helper Widgets ──────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context, ColorScheme colorScheme,
      ResponsiveText responsive) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      title: Text(
        'ORDER DETAILS',
        style: TextStyle(
          fontSize: responsive.fontSize16,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
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
            onPressed: _fetchOrderDetails),
      ],
    );
  }

  Widget _buildHeroInfoChip(
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required bool isDark,
    required ColorScheme colorScheme,
    required Widget child,
    Color? accentColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accentColor != null
              ? accentColor.withValues(alpha: 0.2)
              : colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required ResponsiveText responsive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize11,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border:
            Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    required ResponsiveText responsive,
    required ColorScheme colorScheme,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize13,
            color: colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(
      int currentStep, ColorScheme colorScheme, ResponsiveText responsive) {
    const steps = [
      {'label': 'Placed', 'icon': Icons.check_circle_outline_rounded},
      {'label': 'Processing', 'icon': Icons.inventory_2_outlined},
      {'label': 'Shipped', 'icon': Icons.local_shipping_outlined},
      {'label': 'Delivered', 'icon': Icons.home_outlined},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepNum = (index ~/ 2) + 1;
          final done = currentStep > stepNum;
          return Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: done
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withValues(alpha: 0.7)
                        ],
                      )
                    : null,
                color: done
                    ? null
                    : colorScheme.outline.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          );
        }

        final stepNum = (index ~/ 2) + 1;
        final isDone = currentStep >= stepNum;
        final isCurrent = currentStep == stepNum;
        final step = steps[index ~/ 2];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 34 : 30,
              height: isCurrent ? 34 : 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppTheme.primaryColor
                    : colorScheme.outline.withValues(alpha: 0.12),
                border: Border.all(
                  color: isCurrent
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  width: isCurrent ? 2 : 0,
                ),
                boxShadow: isDone
                    ? [
                        BoxShadow(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 15)
                    : Icon(
                        step['icon'] as IconData,
                        size: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step['label'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: responsive.fontSize10,
                fontWeight:
                    isDone ? FontWeight.bold : FontWeight.w500,
                color: isDone
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        );
      }),
    );
  }
}

double clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
