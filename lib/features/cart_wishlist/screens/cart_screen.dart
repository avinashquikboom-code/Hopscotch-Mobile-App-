import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/cart_wishlist/repositories/cart_wishlist_repository.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/providers/currency_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _includeGiftWrapping = false;
  final double _giftWrappingCost = 250.00;

  Color _parseColor(String? hexCode) {
    if (hexCode == null) return Colors.grey;
    try {
      final code = hexCode.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context)!;

    final double subtotal = cartNotifier.subtotal;
    const double shipping = 150.00;
    final double tax = subtotal * 0.08;
    final double giftCost = _includeGiftWrapping ? _giftWrappingCost : 0.0;
    final double totalAmount = subtotal + shipping + tax + giftCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          l10n.yourBag,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: responsive.fontSize18,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: responsive.spacing(AppTheme.spaceL),
              ),
              child: TextButton(
                onPressed: () => cartNotifier.clearCart(),
                child: Text(
                  l10n.clear,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: l10n.bagEmpty,
              description: l10n.bagEmptyDescription,
              buttonText: l10n.shopNewArrivals,
              onButtonPressed: () => context.go('/'),
            )
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 450),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Items Count Header
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(AppTheme.spaceXL),
                          vertical: responsive.spacing(AppTheme.spaceM),
                        ),
                        child: Text(
                          '${cart.length} ${l10n.items}',
                          style: TextStyle(
                            fontSize: responsive.fontSize12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),

                      // Cart Items
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(AppTheme.spaceXL),
                        ),
                        itemCount: cart.length,
                        separatorBuilder: (context, index) => SizedBox(
                          height: responsive.spacing(AppTheme.spaceL),
                        ),
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          final product = item.product;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusL,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(
                                responsive.spacing(AppTheme.spaceL),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  GestureDetector(
                                    onTap: () => context.push(
                                      '/product/${product.id}?heroTagPrefix=cart',
                                    ),
                                    child: Hero(
                                      tag: 'cart_product_image_${product.id}',
                                      child: Container(
                                        width: responsive.spacing(100),
                                        height: responsive.spacing(100),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusM,
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(
                                              product.imageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: responsive.spacing(AppTheme.spaceL),
                                  ),

                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Category & Remove
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product.subcategory.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => cartNotifier
                                                  .removeFromCart(item.id),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: responsive.iconSize(20),
                                                color: AppTheme.textLightColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: responsive.spacing(
                                            AppTheme.spaceS,
                                          ),
                                        ),

                                        // Product Name
                                        Text(
                                          product.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: responsive.fontSize16,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        SizedBox(
                                          height: responsive.spacing(
                                            AppTheme.spaceS,
                                          ),
                                        ),

                                        // Size & Color
                                        Row(
                                          children: [
                                            if (item.selectedSize != null) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: responsive
                                                      .spacing(AppTheme.spaceS),
                                                  vertical: responsive.spacing(
                                                    4,
                                                  ),
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.selectedSize!,
                                                  style: TextStyle(
                                                    fontSize:
                                                        responsive.fontSize10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme
                                                        .textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(
                                                  AppTheme.spaceS,
                                                ),
                                              ),
                                            ],
                                            if (item.selectedColor != null) ...[
                                              Container(
                                                width: responsive.spacing(16),
                                                height: responsive.spacing(16),
                                                decoration: BoxDecoration(
                                                  color: _parseColor(
                                                    item.selectedColor,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 2,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        SizedBox(
                                          height: responsive.spacing(
                                            AppTheme.spaceM,
                                          ),
                                        ),

                                        // Price & Quantity
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              currency.formatPrice(product.price * item.quantity),
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: responsive.fontSize18,
                                                color:
                                                    AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQtyButton(
                                                    icon: Icons.remove_rounded,
                                                    onTap: () => cartNotifier
                                                        .updateQuantity(
                                                          item.id,
                                                          item.quantity - 1,
                                                        ),
                                                    responsive: responsive,
                                                  ),
                                                  SizedBox(
                                                    width: responsive.spacing(
                                                      40,
                                                    ),
                                                    child: Text(
                                                      item.quantity.toString(),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: responsive
                                                            .fontSize14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppTheme
                                                            .textPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildQtyButton(
                                                    icon: Icons.add_rounded,
                                                    onTap: () => cartNotifier
                                                        .updateQuantity(
                                                          item.id,
                                                          item.quantity + 1,
                                                        ),
                                                    responsive: responsive,
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
                      SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                      // Gift Wrapping
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(AppTheme.spaceXL),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                            responsive.spacing(AppTheme.spaceL),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: responsive.spacing(44),
                                height: responsive.spacing(44),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                ),
                                child: Icon(
                                  Icons.card_giftcard_rounded,
                                  color: AppTheme.primaryColor,
                                  size: responsive.iconSize(24),
                                ),
                              ),
                              SizedBox(
                                width: responsive.spacing(AppTheme.spaceL),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.giftWrapping,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing(2)),
                                    Text(
                                      l10n.giftWrappingDesc,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize11,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceM),
                              Switch(
                                value: _includeGiftWrapping,
                                onChanged: (val) {
                                  setState(() {
                                    _includeGiftWrapping = val;
                                  });
                                },
                                activeThumbColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                      // Order Summary
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(AppTheme.spaceXL),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(
                            responsive.spacing(AppTheme.spaceXL),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusL,
                            ),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.orderSummary,
                                style: TextStyle(
                                  fontSize: responsive.fontSize11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondaryColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceL),
                              ),
                              _buildSummaryRow(
                                l10n.subtotal,
                                currency.formatPrice(subtotal),
                                responsive,
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceS),
                              ),
                              _buildSummaryRow(
                                l10n.shipping,
                                currency.formatPrice(shipping),
                                responsive,
                              ),
                              SizedBox(
                                height: responsive.spacing(AppTheme.spaceS),
                              ),
                              _buildSummaryRow(
                                l10n.taxPercent,
                                currency.formatPrice(tax),
                                responsive,
                              ),
                              if (_includeGiftWrapping) ...[
                                SizedBox(
                                  height: responsive.spacing(AppTheme.spaceS),
                                ),
                                _buildSummaryRow(
                                  l10n.giftWrapping,
                                  currency.formatPrice(_giftWrappingCost),
                                  responsive,
                                ),
                              ],
                              Divider(
                                height: responsive.spacing(AppTheme.spaceXL),
                              ),
                              _buildSummaryRow(
                                l10n.total,
                                currency.formatPrice(totalAmount),
                                responsive,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
                    ],
                  ),
                ),

                // Bottom Panel
                Positioned(
                  bottom: responsive.spacing(25),
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: EdgeInsets.all(
                          responsive.spacing(AppTheme.spaceXL),
                        ).copyWith(bottom: responsive.spacing(40)),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          border: const Border(
                            top: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.totalLabel,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondaryColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  currency.formatPrice(totalAmount),
                                  style: TextStyle(
                                    fontSize: responsive.fontSize24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: responsive.spacing(AppTheme.spaceL),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/checkout'),
                              child: Container(
                                width: double.infinity,
                                height: responsive.spacing(56),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.proceedToCheckout,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
    required ResponsiveText responsive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: responsive.spacing(32),
        height: responsive.spacing(32),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: responsive.iconSize(18),
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ResponsiveText responsive, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize14 : responsive.fontSize13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize16 : responsive.fontSize13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
