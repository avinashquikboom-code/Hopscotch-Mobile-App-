import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/repositories/notification_repository.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/models/product_model.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/utils/navigation_utils.dart';
import 'package:hopscotch/utils/invoice_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

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

  String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) return 'Recently Placed';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return rawDate;
    }
  }

  String _formatPaymentMethod(String method) {
    final clean = method.trim();
    if (clean.isEmpty) return 'ONLINE PAYMENT';
    final upper = clean.replaceAll('_', ' ').toUpperCase();
    if (upper == 'RAZORPAY') return 'RAZORPAY';
    if (upper == 'COD' || upper == 'CASH ON DELIVERY') return 'CASH ON DELIVERY';
    return upper;
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Are you sure you want to cancel Order #${order.id}? Any payment processed will be refunded automatically within 3–5 days.',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Keep Order'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(sheetCtx);
                        try {
                          await ref.read(orderProvider.notifier).cancelOrder(order.id, reason: 'User requested cancellation');
                          ref.read(notificationProvider.notifier).addNotification(
                            title: 'Order Cancelled',
                            body: 'Order #${order.id} has been cancelled.',
                            type: 'order',
                          );
                          _fetchOrderDetails();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Order #${order.id} cancelled successfully.'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text('Confirm Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _reorderAllItems(OrderModel order) {
    final cartNotifier = ref.read(cartProvider.notifier);
    for (final item in order.items) {
      cartNotifier.addToCart(
        item.product,
        size: item.selectedSize,
        color: item.selectedColor,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${order.items.length} item(s) to Cart! 🛒'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'GO TO CART',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
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
        child: CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          placeholder: (_, __) => Container(color: colorScheme.outline.withValues(alpha: 0.1)),
          errorWidget: (_, __, ___) => _buildFallbackThumbnail(colorScheme),
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
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    OrderModel? activeOrder = _detailedOrder ?? widget.order;
    if (activeOrder == null && widget.orderId != null && ordersAsync is AsyncData) {
      final list = ordersAsync.value ?? [];
      try {
        activeOrder = list.firstWhere((o) => o.id == widget.orderId);
      } catch (_) {}
    }

    if (activeOrder == null && _isLoading) {
      return Scaffold(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('ORDER DETAILS')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (activeOrder == null) {
      return Scaffold(
        backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('ORDER DETAILS')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: colorScheme.outline),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Order details not found', style: TextStyle(fontSize: responsive.fontSize15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/my-orders'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('MY ORDERS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final order = activeOrder;
    final isCancelled = order.status.toLowerCase().trim() == 'cancelled';
    final currentStep = _getStatusStep(order.status);
    final statusIcon = _getStatusIcon(order.status);
    final isCancellable = _isCancellable(order.status);
    final formattedDate = _formatDate(order.orderDate);
    final paymentMethodText = _formatPaymentMethod(order.paymentMethod);

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isCancelled ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'ORDER DETAILS',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, color: Colors.white, size: responsive.iconSize(18)),
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
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            onPressed: () => InvoiceGenerator.generateAndDownloadInvoice(order: order),
            tooltip: 'Download Invoice PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
            onPressed: _fetchOrderDetails,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: RefreshIndicator(
          onRefresh: _fetchOrderDetails,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HERO GRADIENT HEADER ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCancelled
                          ? [const Color(0xFFDC2626), const Color(0xFF991B1B)]
                          : [const Color(0xFF0D9488), const Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status pill badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              order.status.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Order ID with 1-tap copy
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${order.id}',
                              style: TextStyle(
                                fontSize: responsive.fontSize20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: order.id));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Order ID copied to clipboard! 📋'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.copy_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('COPY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Placed on $formattedDate', style: TextStyle(fontSize: responsive.fontSize12, color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 16),
                      // Hero info pills
                      Row(
                        children: [
                          _buildHeroInfoChip(icon: Icons.shopping_bag_outlined, label: '${order.items.length} item(s)'),
                          const SizedBox(width: 8),
                          _buildHeroInfoChip(icon: Icons.payments_outlined, label: currency.formatPrice(order.totalAmount)),
                          const SizedBox(width: 8),
                          _buildHeroInfoChip(icon: Icons.credit_card_rounded, label: paymentMethodText),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── MAIN CONTENT CARDS ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── PDF INVOICE CTA BANNER ──
                      GestureDetector(
                        onTap: () => InvoiceGenerator.generateAndDownloadInvoice(order: order),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, size: 24, color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('DOWNLOAD TAX INVOICE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8)),
                                    SizedBox(height: 2),
                                    Text('Official PDF invoice with itemized charges & tax', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── LOYALTY & REWARDS SUMMARY CARD ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.amber.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.orange, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'LOYALTY & REWARDS SUMMARY',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reward Points Earned:', style: TextStyle(fontSize: 12)),
                                Text('100 Pts (Pending Delivery)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Reward Points Redeemed:', style: TextStyle(fontSize: 12)),
                                Text('0 Pts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Wallet Used:', style: TextStyle(fontSize: 12)),
                                Text('₹0.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Cashback Earned:', style: TextStyle(fontSize: 12)),
                                Text('₹50.00', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Reward Transaction ID:', style: TextStyle(fontSize: 12)),
                                Text('TX-RW-${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── ORDER TRACKER CARD ──
                      if (!isCancelled && currentStep > 0) ...[
                        _buildCard(
                          isDark: isDark,
                          colorScheme: colorScheme,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(icon: Icons.timeline_rounded, label: 'ORDER TRACKER', colorScheme: colorScheme, responsive: responsive),
                              const SizedBox(height: 20),
                              _buildTimeline(currentStep, colorScheme, responsive),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── CANCELLED BANNER ──
                      if (isCancelled) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50.withValues(alpha: isDark ? 0.1 : 0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_rounded, color: Colors.red, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This order was cancelled. Any amount paid will be refunded within 3-5 business days.',
                                  style: TextStyle(color: Colors.red.shade900, fontSize: responsive.fontSize12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── ORDER ITEMS LIST ──
                      _buildCard(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSectionHeader(icon: Icons.shopping_bag_rounded, label: 'ORDER ITEMS (${order.items.length})', colorScheme: colorScheme, responsive: responsive),
                                GestureDetector(
                                  onTap: () => _reorderAllItems(order),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.refresh_rounded, size: 14, color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text('REORDER ALL', style: TextStyle(fontSize: responsive.fontSize10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: order.items.length,
                              separatorBuilder: (_, __) => Divider(height: 24, color: colorScheme.outline.withValues(alpha: 0.1)),
                              itemBuilder: (context, idx) {
                                final item = order.items[idx];
                                final itemTotal = item.product.price * item.quantity;
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            style: TextStyle(fontSize: responsive.fontSize13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (item.selectedSize != null) _buildChip('Size: ${item.selectedSize}', colorScheme),
                                              if (item.selectedColor != null) _buildChip('Color: ${item.selectedColor}', colorScheme),
                                              _buildChip('Qty: ${item.quantity}', colorScheme),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            currency.formatPrice(itemTotal),
                                            style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                                          ),
                                          // "Rate this Product" — only for DELIVERED orders
                                          if (order.status.toLowerCase() == 'delivered') ...[
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => context.push(
                                                '/review-submission',
                                                extra: {
                                                  'productId': item.product.id,
                                                  'orderId': order.id,
                                                  'productName': item.product.title,
                                                  'productImageUrl': item.product.imageUrl,
                                                },
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: AppTheme.accentColor, width: 1.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.star_outline_rounded, color: AppTheme.accentColor, size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Rate this Product',
                                                      style: TextStyle(fontSize: responsive.fontSize11, fontWeight: FontWeight.w600, color: AppTheme.accentColor),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── SHIPPING ADDRESS ──
                      _buildCard(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(icon: Icons.location_on_rounded, label: 'SHIPPING ADDRESS', colorScheme: colorScheme, responsive: responsive),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.home_rounded, size: 20, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    order.shippingAddress.trim().isNotEmpty ? order.shippingAddress : 'Standard Shipping Address',
                                    style: TextStyle(fontSize: responsive.fontSize13, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── SELLER / BUSINESS DETAILS ──
                      _buildCard(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(icon: Icons.storefront_rounded, label: 'SELLER DETAILS', colorScheme: colorScheme, responsive: responsive),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                  child: const Icon(Icons.verified_user_rounded, size: 20, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.sellerName.trim().isNotEmpty ? order.sellerName : 'FCI Seller Retail Pvt. Ltd.',
                                        style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Contact: ${order.sellerContact.trim().isNotEmpty ? order.sellerContact : "+91 9876543210"}',
                                        style: TextStyle(fontSize: responsive.fontSize12, fontWeight: FontWeight.w500, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── PRICE BREAKDOWN SUMMARY ──
                      _buildCard(
                        isDark: isDark,
                        colorScheme: colorScheme,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(icon: Icons.receipt_long_rounded, label: 'PAYMENT BREAKDOWN', colorScheme: colorScheme, responsive: responsive),
                            const SizedBox(height: 14),
                            _buildSummaryRow(label: 'Items Subtotal', value: currency.formatPrice(order.subtotal > 0 ? order.subtotal : order.items.fold(0.0, (s, i) => s + i.product.price * i.quantity)), responsive: responsive, colorScheme: colorScheme),
                            const SizedBox(height: 8),
                            _buildSummaryRow(label: 'Shipping Charge', value: order.shippingFee > 0 ? currency.formatPrice(order.shippingFee) : 'FREE', responsive: responsive, colorScheme: colorScheme, valueColor: const Color(0xFF059669)),
                            const SizedBox(height: 8),
                            _buildSummaryRow(label: 'Estimated Tax', value: currency.formatPrice(order.taxAmount), responsive: responsive, colorScheme: colorScheme),
                            if (order.giftWrapped || order.giftWrapCharge > 0) ...[
                              const SizedBox(height: 8),
                              _buildSummaryRow(
                                label: 'Gift Wrapping',
                                value: order.giftWrapCharge > 0
                                    ? currency.formatPrice(order.giftWrapCharge)
                                    : 'FREE',
                                responsive: responsive,
                                colorScheme: colorScheme,
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildSummaryRow(label: 'Payment Method', value: paymentMethodText, responsive: responsive, colorScheme: colorScheme),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Grand Total', style: TextStyle(fontSize: responsive.fontSize15, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
                                Text(currency.formatPrice(order.totalAmount), style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: isCancellable
          ? Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => safeNavigate(context, '/help-center'),
                      icon: const Icon(Icons.headset_mic_rounded, size: 18),
                      label: const Text('Help & Support'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmCancelOrder(context, order),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel Order'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeroInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
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
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required bool isDark, required ColorScheme colorScheme, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String label, required ColorScheme colorScheme, required ResponsiveText responsive}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: responsive.fontSize11, fontWeight: FontWeight.w800, color: colorScheme.onSurface.withValues(alpha: 0.6), letterSpacing: 0.8)),
      ],
    );
  }

  Widget _buildChip(String label, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.outline.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.65))),
    );
  }

  Widget _buildSummaryRow({required String label, required String value, required ResponsiveText responsive, required ColorScheme colorScheme, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: responsive.fontSize13, color: colorScheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: responsive.fontSize13, fontWeight: FontWeight.bold, color: valueColor ?? colorScheme.onSurface)),
      ],
    );
  }

  Widget _buildTimeline(int currentStep, ColorScheme colorScheme, ResponsiveText responsive) {
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
              color: done ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.2),
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
              width: isCurrent ? 34 : 28,
              height: isCurrent ? 34 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.primaryColor : colorScheme.outline.withValues(alpha: 0.12),
                border: Border.all(color: isCurrent ? AppTheme.primaryColor : Colors.transparent, width: isCurrent ? 2 : 0),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                    : Icon(step['icon'] as IconData, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step['label'] as String,
              style: TextStyle(fontSize: responsive.fontSize10, fontWeight: isDone ? FontWeight.bold : FontWeight.w500, color: isDone ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.4)),
            ),
          ],
        );
      }),
    );
  }
}
