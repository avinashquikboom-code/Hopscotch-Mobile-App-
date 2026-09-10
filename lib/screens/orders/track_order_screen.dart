import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  final OrderModel? initialOrder;

  const TrackOrderScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getStepIndex(String status) {
    final s = status.toUpperCase().replaceAll(' ', '_');
    if (s == 'DELIVERED') return 4;
    if (s == 'OUT_FOR_DELIVERY') return 3;
    if (s == 'SHIPPED') return 2;
    if (s == 'CONFIRMED' || s == 'PROCESSING') return 1;
    return 0; // PENDING, PLACED, etc.
  }

  double _getProgressFactor(int stepIndex) {
    return (stepIndex + 1) / 5.0;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cleanId = widget.orderId.replaceAll('#', '').trim();
    final orderAsync = ref.watch(orderDetailProvider(cleanId));

    final OrderModel? order = widget.initialOrder ?? orderAsync.valueOrNull;
    final bool isLoading = order == null && orderAsync.isLoading;
    final bool hasError = order == null && orderAsync.hasError;

    final String effectiveStatus = order?.status ?? 'Processing';
    final int currentStep = _getStepIndex(effectiveStatus);
    final double targetProgress = _getProgressFactor(currentStep);

    if (_progressAnimation.value != targetProgress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: targetProgress,
      ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
      );
      _animationController.forward(from: 0.0);
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Track Order',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : hasError
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: responsive.iconSize(48),
                          color: AppTheme.errorColor,
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                        Text(
                          'Could not load order tracking details',
                          style: TextStyle(
                            fontSize: responsive.fontSize14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                        Text(
                          'Order ID: ${widget.orderId}',
                          style: TextStyle(
                            fontSize: responsive.fontSize12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                        ElevatedButton(
                          onPressed: () => ref.refresh(orderDetailProvider(cleanId)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order ID Card
                      _buildOrderIdCard(order),
                      SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                      // Shipment Details Card (Single Source of Truth from DB)
                      _buildShipmentDetails(order),
                      SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                      // Progress Timeline
                      _buildProgressTimeline(currentStep),
                      SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                      // Delivery Details
                      _buildDeliveryDetails(order),
                      SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                      // Order Items
                      _buildOrderItems(order),
                      SizedBox(height: responsive.spacing(AppTheme.spaceL)),

                      // Help Section
                      _buildHelpSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildOrderIdCard(OrderModel? order) {
    final responsive = context.responsive;
    final displayId = order?.displayOrderId ?? widget.orderId;
    final statusText = (order?.status ?? 'PROCESSING').toUpperCase().replaceAll('_', ' ');

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER ID',
                style: TextStyle(
                  color: AppTheme.textLightColor,
                  letterSpacing: 1,
                  fontSize: responsive.fontSize12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(8),
                  vertical: responsive.spacing(4),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: responsive.fontSize10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Text(
            displayId,
            style: TextStyle(
              fontSize: responsive.fontSize16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceS)),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: responsive.iconSize(14),
                color: AppTheme.textLightColor,
              ),
              SizedBox(width: responsive.spacing(6)),
              Text(
                order?.orderDate.isNotEmpty == true
                    ? 'Placed on: ${order!.orderDate.split('T').first}'
                    : 'Expected delivery: ${_getExpectedDeliveryDate()}',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: responsive.fontSize12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentDetails(OrderModel? order) {
    final responsive = context.responsive;
    final awb = (order?.awbNumber ?? order?.trackingNumber)?.trim();
    final hasAwb = awb != null && awb.isNotEmpty;
    final courier = order?.courierName?.trim() ?? '';

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_rounded,
                size: responsive.iconSize(18),
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: responsive.spacing(8)),
              Text(
                'SHIPMENT DETAILS',
                style: TextStyle(
                  color: AppTheme.textLightColor,
                  letterSpacing: 1,
                  fontSize: responsive.fontSize12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          if (!hasAwb) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: responsive.iconSize(16),
                    color: AppTheme.textLightColor,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Expanded(
                    child: Text(
                      'Tracking information will be available after shipment.',
                      style: TextStyle(
                        fontSize: responsive.fontSize12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Courier Partner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shipping Company',
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  courier.isNotEmpty ? courier : 'Standard Logistics',
                  style: TextStyle(
                    fontSize: responsive.fontSize13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            // AWB Number with Copy
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AWB Number',
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      awb,
                      style: TextStyle(
                        fontSize: responsive.fontSize13,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: awb));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('AWB copied'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(8),
                          vertical: responsive.spacing(4),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: responsive.iconSize(11),
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: responsive.spacing(4)),
                            Text(
                              'Copy',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: responsive.fontSize10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            // Track Order Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openCourierTracking(
                  courier,
                  awb,
                  order?.trackingUrl,
                ),
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: responsive.iconSize(16),
                ),
                label: const Text('Track Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(10),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(int currentStep) {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORDER STATUS',
            style: TextStyle(
              color: AppTheme.textLightColor,
              letterSpacing: 1,
              fontSize: responsive.fontSize12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  // Progress Bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.secondaryColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  // Timeline Steps
                  _buildTimelineStep(
                    'Order Placed',
                    'Your order has been placed successfully',
                    Icons.check_circle_rounded,
                    0 <= currentStep,
                    0 == currentStep,
                  ),
                  _buildTimelineStep(
                    'Order Confirmed',
                    'Seller has confirmed and packed your order',
                    Icons.inventory_2_rounded,
                    1 <= currentStep,
                    1 == currentStep,
                  ),
                  _buildTimelineStep(
                    'Shipped',
                    'Your order is handed over to the courier partner',
                    Icons.local_shipping_rounded,
                    2 <= currentStep,
                    2 == currentStep,
                  ),
                  _buildTimelineStep(
                    'Out for Delivery',
                    'Delivery executive is on the way to your address',
                    Icons.delivery_dining_rounded,
                    3 <= currentStep,
                    3 == currentStep,
                  ),
                  _buildTimelineStep(
                    'Delivered',
                    'Order package delivered successfully',
                    Icons.home_rounded,
                    4 <= currentStep,
                    4 == currentStep,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String description,
    IconData icon,
    bool isCompleted,
    bool isCurrent,
  ) {
    final responsive = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceL)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: responsive.spacing(40),
            height: responsive.spacing(40),
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : AppTheme.borderColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted
                  ? AppTheme.primaryColor
                  : AppTheme.textLightColor,
              size: responsive.iconSize(20),
            ),
          ),
          SizedBox(width: responsive.spacing(AppTheme.spaceM)),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize14,
                    fontWeight: isCompleted
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isCompleted
                        ? AppTheme.textPrimaryColor
                        : AppTheme.textLightColor,
                  ),
                ),
                SizedBox(height: responsive.spacing(2)),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: responsive.fontSize12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDetails(OrderModel? order) {
    final responsive = context.responsive;
    final addressText = order?.shippingAddress.isNotEmpty == true
        ? order!.shippingAddress
        : 'Standard Shipping Address';

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DELIVERY ADDRESS',
            style: TextStyle(
              color: AppTheme.textLightColor,
              letterSpacing: 1,
              fontSize: responsive.fontSize12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: AppTheme.primaryColor,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceM)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Destination',
                      style: TextStyle(
                        fontSize: responsive.fontSize14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(4)),
                    Text(
                      addressText,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: responsive.fontSize12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(OrderModel? order) {
    final responsive = context.responsive;
    final items = order?.items ?? [];

    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER ITEMS',
                style: TextStyle(
                  color: AppTheme.textLightColor,
                  letterSpacing: 1,
                  fontSize: responsive.fontSize12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} item(s)',
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(AppTheme.spaceM)),
              child: Text(
                'Item details available upon package dispatch.',
                style: TextStyle(
                  fontSize: responsive.fontSize12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: responsive.spacing(AppTheme.spaceM)),
              itemBuilder: (context, index) {
                final item = items[index];
                final variantStr = [
                  if (item.selectedSize != null && item.selectedSize!.isNotEmpty)
                    'Size: ${item.selectedSize}',
                  if (item.selectedColor != null && item.selectedColor!.isNotEmpty)
                    'Color: ${item.selectedColor}',
                ].join(' | ');

                return _buildOrderItem(
                  item.product.imageUrl,
                  item.product.title,
                  variantStr.isNotEmpty ? variantStr : 'Standard',
                  '₹${(item.product.price * item.quantity).toStringAsFixed(0)}',
                  item.quantity,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    String imageUrl,
    String title,
    String variant,
    String price,
    int quantity,
  ) {
    final responsive = context.responsive;
    return Row(
      children: [
        // Product Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          child: Image.network(
            imageUrl,
            width: responsive.spacing(56),
            height: responsive.spacing(56),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: responsive.spacing(56),
              height: responsive.spacing(56),
              color: AppTheme.backgroundColor,
              child: Icon(
                Icons.checkroom_rounded,
                color: AppTheme.textLightColor,
                size: responsive.iconSize(24),
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(AppTheme.spaceM)),
        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: responsive.fontSize14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: responsive.spacing(2)),
              Text(
                variant,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: responsive.fontSize12,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: responsive.fontSize14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Qty: $quantity',
                    style: TextStyle(
                      color: AppTheme.textLightColor,
                      fontSize: responsive.fontSize12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEED HELP?',
            style: TextStyle(
              color: AppTheme.textLightColor,
              letterSpacing: 1,
              fontSize: responsive.fontSize12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            children: [
              Expanded(
                child: _buildHelpOption(
                  Icons.chat_bubble_outline_rounded,
                  'Chat with us',
                  () {},
                ),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceM)),
              Expanded(
                child: _buildHelpOption(
                  Icons.phone_outlined,
                  'Call support',
                  () {},
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _buildHelpOption(Icons.email_outlined, 'Email support', () {}),
        ],
      ),
    );
  }

  Widget _buildHelpOption(IconData icon, String title, VoidCallback onTap) {
    final responsive = context.responsive;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: responsive.iconSize(18),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceM)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCourierTracking(
    String courier,
    String awb,
    String? directUrl,
  ) async {
    final cleanAwb = awb.trim();
    final cleanDirectUrl = directUrl?.trim();
    if (cleanAwb.isEmpty && (cleanDirectUrl == null || cleanDirectUrl.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tracking information is not available yet.')),
        );
      }
      return;
    }
    String url = cleanDirectUrl ?? '';
    if (url.isEmpty || !url.startsWith('http')) {
      final c = courier.toLowerCase();
      if (c.contains('delhivery')) {
        url = 'https://www.delhivery.com/track/package/$cleanAwb';
      } else if (c.contains('bluedart')) {
        url =
            'https://www.bluedart.com/tracking?handler=tnt&action=custtrack&trackid=$cleanAwb';
      } else if (c.contains('dtdc')) {
        url =
            'https://www.dtdc.in/tracking/shipment-tracking.asp?trkType=awb&strCnno=$cleanAwb';
      } else if (c.contains('xpressbees')) {
        url = 'https://www.xpressbees.com/track?isAwb=true&trackid=$cleanAwb';
      } else if (c.contains('india post') || c.contains('speed post')) {
        url = 'https://www.indiapost.gov.in/_layouts/15/dpt.cpt.trackconsignment/tracking.aspx';
      } else if (c.contains('ecom')) {
        url = 'https://ecomexpress.in/tracking/?awb=$cleanAwb';
      } else if (c.contains('shiprocket')) {
        url = 'https://shiprocket.co/tracking/$cleanAwb';
      } else {
        url =
            'https://www.google.com/search?q=${Uri.encodeComponent('$courier tracking $cleanAwb')}';
      }
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open tracking URL')),
        );
      }
    }
  }

  String _getExpectedDeliveryDate() {
    final date = DateTime.now().add(const Duration(days: 3));
    return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
