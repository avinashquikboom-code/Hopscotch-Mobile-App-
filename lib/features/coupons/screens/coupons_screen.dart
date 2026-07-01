import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopscotch/core/theme/app_theme.dart';
import 'package:hopscotch/core/utils/responsive_text.dart';

class CouponModel {
  final String id;
  final String title;
  final String description;
  final String code;
  final int discount;
  final String type;
  final double minOrder;
  final double maxDiscount;
  final DateTime expiry;
  final String category;
  final bool isExclusive;
  final bool isApplied;

  CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discount,
    required this.type,
    required this.minOrder,
    required this.maxDiscount,
    required this.expiry,
    required this.category,
    this.isExclusive = false,
    this.isApplied = false,
  });

  CouponModel copyWith({bool? isApplied}) {
    return CouponModel(
      id: id,
      title: title,
      description: description,
      code: code,
      discount: discount,
      type: type,
      minOrder: minOrder,
      maxDiscount: maxDiscount,
      expiry: expiry,
      category: category,
      isExclusive: isExclusive,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final List<CouponModel> _coupons = [
    CouponModel(
      id: '1',
      title: 'Fashion Fiesta',
      description: '25% off on all fashion items',
      code: 'FASHION25',
      discount: 25,
      type: 'percentage',
      minOrder: 599,
      maxDiscount: 500,
      expiry: DateTime.now().add(const Duration(days: 10)),
      category: 'Fashion',
      isExclusive: true,
    ),
    CouponModel(
      id: '2',
      title: 'Footwear Special',
      description: 'Flat ₹300 off on footwear',
      code: 'SHOES300',
      discount: 300,
      type: 'flat',
      minOrder: 799,
      maxDiscount: 300,
      expiry: DateTime.now().add(const Duration(days: 5)),
      category: 'Footwear',
    ),
    CouponModel(
      id: '3',
      title: 'Accessory Deal',
      description: '20% off on accessories',
      code: 'ACC20',
      discount: 20,
      type: 'percentage',
      minOrder: 399,
      maxDiscount: 200,
      expiry: DateTime.now().add(const Duration(days: 15)),
      category: 'Accessories',
    ),
    CouponModel(
      id: '4',
      title: 'New User Bonus',
      description: '₹100 off on first purchase',
      code: 'NEW100',
      discount: 100,
      type: 'flat',
      minOrder: 299,
      maxDiscount: 100,
      expiry: DateTime.now().add(const Duration(days: 30)),
      category: 'All',
      isExclusive: true,
    ),
    CouponModel(
      id: '5',
      title: 'Weekend Wonder',
      description: '15% off on weekends',
      code: 'WEEKEND15',
      discount: 15,
      type: 'percentage',
      minOrder: 499,
      maxDiscount: 300,
      expiry: DateTime.now().add(const Duration(days: 2)),
      category: 'All',
    ),
  ];

  void _copyCode(String code) {
    final responsive = context.responsive;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code $code copied!',
          style: TextStyle(fontSize: responsive.fontSize14),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _applyCoupon(CouponModel coupon) {
    final responsive = context.responsive;
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _coupons.indexWhere((c) => c.id == coupon.id);
      if (index != -1) {
        _coupons[index] = coupon.copyWith(isApplied: !coupon.isApplied);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          coupon.isApplied ? 'Coupon removed' : 'Coupon applied!',
          style: TextStyle(fontSize: responsive.fontSize14),
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Coupons',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, size: responsive.iconSize(24)),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Coupon Stats
          _buildCouponStats(),
          // Coupons List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
              itemCount: _coupons.length,
              itemBuilder: (context, index) {
                final coupon = _coupons[index];
                return TweenAnimationBuilder<double>(
                  key: ValueKey(coupon.id),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: responsive.spacing(AppTheme.spaceL),
                          ),
                          child: _buildCouponCard(coupon),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponStats() {
    final responsive = context.responsive;
    final activeCoupons = _coupons.where((c) => !c.isApplied).length;
    final appliedCoupons = _coupons.where((c) => c.isApplied).length;

    return Container(
      margin: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.intenseShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Active', activeCoupons.toString()),
          Container(
            width: 1,
            height: responsive.spacing(40),
            color: Colors.white.withValues(alpha: 0.3),
          ),
          _buildStatItem('Applied', appliedCoupons.toString()),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final responsive = context.responsive;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize12,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    final responsive = context.responsive;
    final daysLeft = coupon.expiry.difference(DateTime.now()).inDays;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        color: AppTheme.surfaceColor,
        border: Border.all(
          color: coupon.isApplied
              ? AppTheme.primaryColor
              : AppTheme.borderColor,
          width: coupon.isApplied ? 2 : 1,
        ),
        boxShadow: coupon.isApplied
            ? AppTheme.intenseShadow
            : AppTheme.softShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          children: [
            Row(
              children: [
                // Left - Discount
                Container(
                  width: responsive.spacing(80),
                  height: responsive.spacing(80),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.secondaryColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          coupon.type == 'percentage'
                              ? '${coupon.discount}%'
                              : '₹${coupon.discount}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: responsive.fontSize20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'OFF',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: responsive.fontSize10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                // Middle - Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            coupon.title.toUpperCase(),
                            style: TextStyle(
                              fontSize: responsive.fontSize14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          if (coupon.isExclusive)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.spacing(6),
                                vertical: responsive.spacing(2),
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EXCLUSIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: responsive.fontSize8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(4)),
                      Text(
                        coupon.description,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: responsive.fontSize12,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(8)),
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: responsive.iconSize(12),
                            color: AppTheme.textLightColor,
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Text(
                            coupon.category,
                            style: TextStyle(
                              color: AppTheme.textLightColor,
                              fontSize: responsive.fontSize12,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(12)),
                          Icon(
                            Icons.access_time,
                            size: responsive.iconSize(12),
                            color: AppTheme.textLightColor,
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Text(
                            '${daysLeft}d left',
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
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            // Divider with cutout effect
            Row(
              children: [
                for (int i = 0; i < 8; i++)
                  Expanded(
                    child: Container(
                      height: 1,
                      margin: EdgeInsets.only(
                        right: i < 7 ? responsive.spacing(4) : 0,
                        left: i > 0 ? responsive.spacing(4) : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        border: i == 0 || i == 7
                            ? Border.all(color: AppTheme.surfaceColor, width: 2)
                            : null,
                        borderRadius: i == 0
                            ? const BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              )
                            : i == 7
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceM)),
            // Code and Actions
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(AppTheme.spaceM),
                      vertical: responsive.spacing(AppTheme.spaceS),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(color: AppTheme.borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        Text(
                          coupon.code,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontSize: responsive.fontSize14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                // Copy Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _copyCode(coupon.code),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(16),
                        vertical: responsive.spacing(10),
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: responsive.iconSize(18),
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceS)),
                // Apply Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _applyCoupon(coupon),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(20),
                        vertical: responsive.spacing(10),
                      ),
                      decoration: BoxDecoration(
                        color: coupon.isApplied
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            coupon.isApplied ? Icons.check : Icons.add,
                            size: responsive.iconSize(16),
                            color: coupon.isApplied
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                          SizedBox(width: responsive.spacing(6)),
                          Text(
                            coupon.isApplied ? 'APPLIED' : 'APPLY',
                            style: TextStyle(
                              color: coupon.isApplied
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: responsive.fontSize12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final responsive = context.responsive;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXL),
            topRight: Radius.circular(AppTheme.radiusXL),
          ),
        ),
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Coupons',
              style: TextStyle(
                fontSize: responsive.fontSize20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            _buildFilterOption('All Coupons', true),
            _buildFilterOption('Exclusive Only', false),
            _buildFilterOption('Expiring Soon', false),
            SizedBox(height: responsive.spacing(AppTheme.spaceL)),
            SizedBox(
              width: double.infinity,
              height: responsive.spacing(56),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Text(
                  'Apply Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: responsive.fontSize14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    final responsive = context.responsive;
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(AppTheme.spaceM)),
      child: Row(
        children: [
          Container(
            width: responsive.spacing(20),
            height: responsive.spacing(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: 2,
              ),
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    size: responsive.iconSize(12),
                    color: Colors.white,
                  )
                : null,
          ),
          SizedBox(width: responsive.spacing(AppTheme.spaceM)),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
