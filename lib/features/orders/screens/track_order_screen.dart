import 'package:flutter/material.dart';
import 'package:hopscotch/core/theme/app_theme.dart';
import 'package:hopscotch/core/utils/responsive_text.dart';

enum OrderStatus {
  placed,
  confirmed,
  shipped,
  outForDelivery,
  delivered,
}

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 0.6).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Track Order', style: TextStyle(fontSize: responsive.fontSize18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID Card
            _buildOrderIdCard(),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Progress Timeline
            _buildProgressTimeline(),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Delivery Details
            _buildDeliveryDetails(),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Order Items
            _buildOrderItems(),
            SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
            // Help Section
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderIdCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ORDER ID',
                style: TextStyle(
                  color: AppTheme.textLightColor,
                  letterSpacing: 1,
                  fontSize: responsive.fontSize12,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(8),
                  vertical: responsive.spacing(4),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  'IN TRANSIT',
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
            widget.orderId,
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
                'Expected delivery: ${_getExpectedDeliveryDate()}',
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

  Widget _buildProgressTimeline() {
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
                      widthFactor: _progressAnimation.value,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
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
                    Icons.check_circle,
                    true,
                    true,
                  ),
                  _buildTimelineStep(
                    'Order Confirmed',
                    'Seller has confirmed your order',
                    Icons.check_circle,
                    true,
                    true,
                  ),
                  _buildTimelineStep(
                    'Shipped',
                    'Your order has been shipped',
                    Icons.local_shipping,
                    true,
                    true,
                  ),
                  _buildTimelineStep(
                    'Out for Delivery',
                    'Your order is out for delivery',
                    Icons.delivery_dining,
                    false,
                    false,
                  ),
                  _buildTimelineStep(
                    'Delivered',
                    'Order delivered successfully',
                    Icons.home,
                    false,
                    false,
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
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : AppTheme.borderColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? AppTheme.primaryColor : AppTheme.textLightColor,
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
                    fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? AppTheme.textPrimaryColor : AppTheme.textLightColor,
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

  Widget _buildDeliveryDetails() {
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
            'DELIVERY ADDRESS',
            style: TextStyle(
              color: AppTheme.textLightColor,
              letterSpacing: 1,
              fontSize: responsive.fontSize12,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(
                  Icons.location_on,
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
                      'John Doe',
                      style: TextStyle(
                        fontSize: responsive.fontSize14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(2)),
                    Text(
                      '123 Fashion Street, Mumbai, Maharashtra 400001',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: responsive.fontSize12,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(2)),
                    Text(
                      '+91 98765 43210',
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
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
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
            'ORDER ITEMS',
            style: TextStyle(
              color: AppTheme.textLightColor,
              letterSpacing: 1,
              fontSize: responsive.fontSize12,
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _buildOrderItem(
            'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=200',
            'Floral Summer Dress',
            'Size: M | Color: Pink',
            '₹1,299',
            1,
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          _buildOrderItem(
            'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=200',
            'Classic White Sneakers',
            'Size: 8 | Color: White',
            '₹2,499',
            1,
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
            width: responsive.spacing(60),
            height: responsive.spacing(60),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: responsive.spacing(60),
                height: responsive.spacing(60),
                decoration: BoxDecoration(
                  color: AppTheme.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
              );
            },
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
                style: TextStyle(
                  fontSize: responsive.fontSize14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: responsive.fontSize14,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(AppTheme.spaceS)),
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
            ),
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceM)),
          Row(
            children: [
              Expanded(
                child: _buildHelpOption(
                  Icons.chat_bubble_outline,
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
          _buildHelpOption(
            Icons.email_outlined,
            'Email support',
            () {},
          ),
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
        splashColor: AppTheme.primaryColor.withOpacity(0.1),
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
                size: responsive.iconSize(20),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceM)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExpectedDeliveryDate() {
    final date = DateTime.now().add(const Duration(days: 3));
    return '${date.day} ${_getMonthName(date.month)}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
