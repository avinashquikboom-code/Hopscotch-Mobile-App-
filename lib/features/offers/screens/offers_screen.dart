import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hopscotch/core/theme/app_theme.dart';
import 'package:hopscotch/core/utils/responsive_text.dart';
import 'package:hopscotch/core/widgets/custom_button.dart';

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String code;
  final int discount;
  final String type; // 'percentage' or 'flat'
  final double minOrder;
  final DateTime expiry;
  final String imageUrl;
  final bool isApplied;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discount,
    required this.type,
    required this.minOrder,
    required this.expiry,
    required this.imageUrl,
    this.isApplied = false,
  });

  OfferModel copyWith({bool? isApplied}) {
    return OfferModel(
      id: id,
      title: title,
      description: description,
      code: code,
      discount: discount,
      type: type,
      minOrder: minOrder,
      expiry: expiry,
      imageUrl: imageUrl,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<OfferModel> _offers = [
    OfferModel(
      id: '1',
      title: 'Summer Sale',
      description: 'Get 30% off on all summer collection',
      code: 'SUMMER30',
      discount: 30,
      type: 'percentage',
      minOrder: 999,
      expiry: DateTime.now().add(const Duration(days: 7)),
      imageUrl:
          'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=400',
    ),
    OfferModel(
      id: '2',
      title: 'First Order Discount',
      description: 'Flat ₹200 off on your first order',
      code: 'FIRST200',
      discount: 200,
      type: 'flat',
      minOrder: 499,
      expiry: DateTime.now().add(const Duration(days: 30)),
      imageUrl:
          'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
    ),
    OfferModel(
      id: '3',
      title: 'Weekend Special',
      description: 'Extra 15% off on weekends',
      code: 'WEEKEND15',
      discount: 15,
      type: 'percentage',
      minOrder: 799,
      expiry: DateTime.now().add(const Duration(days: 2)),
      imageUrl:
          'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=400',
    ),
    OfferModel(
      id: '4',
      title: 'Free Shipping',
      description: 'Free shipping on orders above ₹999',
      code: 'FREESHIP',
      discount: 0,
      type: 'flat',
      minOrder: 999,
      expiry: DateTime.now().add(const Duration(days: 15)),
      imageUrl:
          'https://images.unsplash.com/photo-1472851294608-062f824d29cc?w=400',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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

  void _applyOffer(OfferModel offer) {
    final responsive = context.responsive;
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _offers.indexWhere((o) => o.id == offer.id);
      if (index != -1) {
        _offers[index] = offer.copyWith(isApplied: !offer.isApplied);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          offer.isApplied ? 'Offer removed' : 'Offer applied!',
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
          'Offers & Deals',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        itemCount: _offers.length,
        itemBuilder: (context, index) {
          final offer = _offers[index];
          return TweenAnimationBuilder<double>(
            key: ValueKey(offer.id),
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: responsive.spacing(AppTheme.spaceL),
                    ),
                    child: _buildOfferCard(offer),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer) {
    final responsive = context.responsive;
    final daysLeft = offer.expiry.difference(DateTime.now()).inDays;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        color: AppTheme.surfaceColor,
        border: Border.all(
          color: offer.isApplied ? AppTheme.primaryColor : AppTheme.borderColor,
          width: offer.isApplied ? 2 : 1,
        ),
        boxShadow: offer.isApplied
            ? AppTheme.intenseShadow
            : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusXL),
              topRight: Radius.circular(AppTheme.radiusXL),
            ),
            child: Stack(
              children: [
                Image.network(
                  offer.imageUrl,
                  height: responsive.spacing(160),
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: responsive.spacing(160),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor.withValues(alpha: 0.3),
                            AppTheme.secondaryColor.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Discount Badge
                Positioned(
                  top: responsive.spacing(AppTheme.spaceM),
                  left: responsive.spacing(AppTheme.spaceM),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(12),
                      vertical: responsive.spacing(6),
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      offer.type == 'percentage'
                          ? '${offer.discount}% OFF'
                          : '₹${offer.discount} OFF',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: responsive.fontSize12,
                      ),
                    ),
                  ),
                ),
                // Expiry Badge
                Positioned(
                  top: responsive.spacing(AppTheme.spaceM),
                  right: responsive.spacing(AppTheme.spaceM),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(10),
                      vertical: responsive.spacing(5),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: responsive.iconSize(12),
                        ),
                        SizedBox(width: responsive.spacing(4)),
                        Text(
                          '${daysLeft}d left',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.fontSize11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content Section
          Padding(
            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  offer.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: responsive.fontSize16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                // Description
                Text(
                  offer.description,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: responsive.fontSize14,
                  ),
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                // Code Section
                Container(
                  padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceM)),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.borderColor, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CODE',
                              style: TextStyle(
                                color: AppTheme.textLightColor,
                                fontSize: responsive.fontSize10,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(2)),
                            Text(
                              offer.code,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontSize: responsive.fontSize16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                      // Copy Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _copyCode(offer.code),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          splashColor: AppTheme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(16),
                              vertical: responsive.spacing(10),
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusS,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.copy,
                                  size: responsive.iconSize(16),
                                  color: AppTheme.primaryColor,
                                ),
                                SizedBox(width: responsive.spacing(6)),
                                Text(
                                  'COPY',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
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
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                // Min Order Info
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: responsive.iconSize(14),
                      color: AppTheme.textLightColor,
                    ),
                    SizedBox(width: responsive.spacing(4)),
                    Text(
                      'Min order ₹${offer.minOrder.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppTheme.textLightColor,
                        fontSize: responsive.fontSize12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                // Apply Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(56),
                  child: CustomButton(
                    text: offer.isApplied ? 'APPLIED' : 'APPLY OFFER',
                    onPressed: () => _applyOffer(offer),
                    isOutlined: !offer.isApplied,
                    backgroundColor: offer.isApplied
                        ? AppTheme.primaryColor
                        : null,
                    icon: offer.isApplied ? Icons.check_circle : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
