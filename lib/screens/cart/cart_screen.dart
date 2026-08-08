import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/providers/gift_wrap_provider.dart';
import 'package:hopscotch/providers/coupon_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.trim().isEmpty) return Colors.teal;
    final str = colorStr.trim().toLowerCase();
    const colorMap = <String, Color>{
      'black': Colors.black,
      'white': Colors.white,
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'navy': Color(0xFF000080),
      'green': Color(0xFF43A047),
      'yellow': Color(0xFFFDD835),
      'orange': Color(0xFFFB8C00),
      'purple': Color(0xFF8E24AA),
      'pink': Color(0xFFD81B60),
      'grey': Color(0xFF757575),
      'gray': Color(0xFF757575),
      'brown': Color(0xFF6D4C41),
      'teal': Color(0xFF00897B),
      'cyan': Color(0xFF00ACC1),
      'gold': Color(0xFFFFD700),
    };

    if (colorMap.containsKey(str)) return colorMap[str]!;

    try {
      String hex = colorStr.replaceAll('#', '').replaceAll('0x', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}

    return Colors.teal;
  }

  String _resolveCartItemImage(dynamic item) {
    if (item is CartItemModel &&
        item.selectedImage != null &&
        item.selectedImage!.trim().isNotEmpty) {
      return AppUrls.resolveUrl(item.selectedImage!);
    }
    try {
      if (item.selectedImage != null &&
          item.selectedImage.toString().trim().isNotEmpty) {
        return AppUrls.resolveUrl(item.selectedImage.toString());
      }
    } catch (_) {}

    final product = item.product;
    final allImages = [
      if (product.imageUrl.isNotEmpty) product.imageUrl as String,
      ...List<String>.from(product.additionalImages ?? []),
    ];

    if (item.selectedColor != null &&
        item.selectedColor!.toString().trim().isNotEmpty) {
      final colorLower = item.selectedColor!.toString().trim().toLowerCase();

      if (product.variants != null) {
        for (final v in product.variants) {
          if (v.color?.toLowerCase() == colorLower &&
              v.imageUrl != null &&
              v.imageUrl!.isNotEmpty) {
            return AppUrls.resolveUrl(v.imageUrl!);
          }
        }
      }

      final matchedImage = allImages.firstWhere(
        (url) => url.toLowerCase().contains(colorLower),
        orElse: () => '',
      );
      if (matchedImage.isNotEmpty) return AppUrls.resolveUrl(matchedImage);
    }

    return AppUrls.resolveUrl(product.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currency = ref.watch(currencyProvider);
    final responsive = context.responsive;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double subtotal = cartNotifier.subtotal;
    final double shipping = cartNotifier.shippingFee;
    final double tax = cartNotifier.taxAmount;
    final bool hasInclusive = cartNotifier.hasInclusiveTax;

    final giftWrapConfig =
        ref.watch(giftWrapConfigProvider).valueOrNull ??
        const GiftWrapConfig(enabled: true, charge: 49.0);
    final isGiftWrapped = ref.watch(isGiftWrappedProvider);

    double giftWrappingCost = giftWrapConfig.charge;
    double customGiftWrapSum = 0.0;
    bool hasCustomGiftWrap = false;
    for (final item in cart) {
      if (item.product.isGiftWrapAvailable && item.product.giftWrapCharge > 0) {
        customGiftWrapSum += item.product.giftWrapCharge;
        hasCustomGiftWrap = true;
      }
    }
    if (hasCustomGiftWrap && customGiftWrapSum > 0) {
      giftWrappingCost = customGiftWrapSum;
    }

    final double giftCost = (isGiftWrapped && giftWrapConfig.enabled)
        ? giftWrappingCost
        : 0.0;
    final double couponDiscount = ref
        .read(appliedCouponProvider.notifier)
        .calculateDiscount(subtotal);
    final double totalAmount = (subtotal - couponDiscount + shipping + cartNotifier.exclusiveTaxAmount + giftCost)
        .clamp(0.0, double.infinity);

    // Free shipping threshold calculations
    const double freeShippingThreshold = 1000.0;
    final double remainingForFreeShipping = freeShippingThreshold - subtotal;
    final double freeShippingProgress = (subtotal / freeShippingThreshold)
        .clamp(0.0, 1.0);

    final clearText = l10n?.clear ?? 'Clear';
    final orderSummaryText = l10n?.orderSummary ?? 'Order Summary';
    final subtotalText = l10n?.subtotal ?? 'Subtotal';
    final shippingText = l10n?.shipping ?? 'Shipping';
    final taxPercentText = l10n?.tax ?? 'Taxes';
    final totalText = l10n?.total ?? 'Total';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        title: Text(
          'Your Bag',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  cartNotifier.clearCart();
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: responsive.iconSize(18),
                  color: colorScheme.error,
                ),
                label: Text(
                  clearText,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? _buildEmptyBagState(
              context,
              responsive,
              colorScheme,
              isDark,
              l10n,
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      responsive.spacing(AppTheme.spaceXL),
                      responsive.spacing(AppTheme.spaceM),
                      responsive.spacing(AppTheme.spaceXL),
                      160,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCartHeroStrip(
                          context,
                          itemCount: cart.length,
                          totalAmount: totalAmount,
                          currency: currency,
                          isDark: isDark,
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                        _buildFreeShippingBar(
                          context,
                          subtotal: subtotal,
                          progress: freeShippingProgress,
                          remaining: remainingForFreeShipping,
                          currency: currency,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                        _CartSectionTitle(
                          text: '${cart.length} ${l10n?.items ?? 'items'}',
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceM)),

                        _CartGroupedCard(
                          children: List.generate(cart.length * 2 - 1, (index) {
                            if (index.isOdd) {
                              return Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.35,
                                ),
                              );
                            }
                            final itemIndex = index ~/ 2;
                            final item = cart[itemIndex];
                            return _buildCartItemCard(
                              context,
                              item: item,
                              cartNotifier: cartNotifier,
                              currency: currency,
                              responsive: responsive,
                              colorScheme: colorScheme,
                              isDark: isDark,
                              grouped: true,
                            );
                          }),
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                        _CartSectionTitle(text: l10n?.giftWrapping ?? 'Gift wrapping'),
                        SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                        _buildGiftWrappingCard(
                          context,
                          responsive,
                          colorScheme,
                          isDark,
                          currency,
                          isGiftWrapped: isGiftWrapped,
                          giftWrappingCost: giftWrappingCost,
                          isEnabled: giftWrapConfig.enabled,
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

                        _CartSectionTitle(text: orderSummaryText),
                        SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                        _buildOrderSummaryCard(
                          context,
                          responsive: responsive,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          currency: currency,
                          subtotal: subtotal,
                          shipping: shipping,
                          tax: tax,
                          hasInclusive: hasInclusive,
                          giftCost: giftCost,
                          totalAmount: totalAmount,
                          orderSummaryText: orderSummaryText,
                          subtotalText: subtotalText,
                          shippingText: shippingText,
                          taxPercentText: taxPercentText,
                          totalText: totalText,
                          cartItems: cart,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      responsive.spacing(AppTheme.spaceXL),
                      responsive.spacing(AppTheme.spaceM),
                      responsive.spacing(AppTheme.spaceXL),
                      MediaQuery.of(context).padding.bottom +
                          responsive.spacing(AppTheme.spaceM),
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                totalText,
                                style: TextStyle(
                                  fontSize: responsive.fontSize11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                ),
                              ),
                              Text(
                                currency.formatPrice(totalAmount),
                                style: TextStyle(
                                  fontSize: responsive.fontSize20,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: SizedBox(
                            height: responsive.spacing(48),
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.go('/checkout');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusM,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      l10n?.proceedToCheckout ?? 'Checkout',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: responsive.iconSize(16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCartHeroStrip(
    BuildContext context, {
    required int itemCount,
    required double totalAmount,
    required dynamic currency,
    required bool isDark,
  }) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppColors.darkPrimaryBg, AppColors.darkSurface]
              : [AppColors.primary, AppColors.primaryHover],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: Colors.white,
              size: responsive.iconSize(26),
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount item${itemCount == 1 ? '' : 's'} in your bag',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: responsive.fontSize16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total ${currency.formatPrice(totalAmount)} · Free shipping over ₹1,000',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: responsive.fontSize11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Redesigned Empty Bag State ─────────────────────────────────────────────
  Widget _buildEmptyBagState(
    BuildContext context,
    ResponsiveText responsive,
    ColorScheme colorScheme,
    bool isDark,
    AppLocalizations? l10n,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withValues(
                  alpha: isDark ? 0.12 : 0.06,
                ),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/success.json',
                  width: 110,
                  height: 110,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.shopping_bag_outlined,
                      size: 72,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              l10n?.bagEmpty ?? 'Your Bag is Empty',
              style: TextStyle(
                fontSize: responsive.fontSize18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n?.bagEmptyDescription ??
                  'Explore our curated collections and discover pieces tailored to your style.',
              style: TextStyle(
                fontSize: responsive.fontSize13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Quick Category Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _categoryChip(context, 'New Arrivals', '/categories'),
                _categoryChip(context, 'Clothing', '/categories'),
                _categoryChip(context, 'Footwear', '/categories'),
                _categoryChip(context, 'Accessories', '/categories'),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go('/');
              },
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(
                l10n?.shopNewArrivals ?? 'Shop New Arrivals',
                style: TextStyle(
                  fontSize: responsive.fontSize12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(BuildContext context, String label, String route) {
    final colorScheme = Theme.of(context).colorScheme;
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () => context.go(route),
    );
  }

  // ── Free Shipping Progress Bar ──────────────────────────────────────────────
  Widget _buildFreeShippingBar(
    BuildContext context, {
    required double subtotal,
    required double progress,
    required double remaining,
    required dynamic currency,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final bool hasFreeShipping = subtotal > 999;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasFreeShipping
              ? [const Color(0xFF0F766E), const Color(0xFF0D9488)]
              : [
                  AppTheme.primaryColor.withValues(alpha: 0.12),
                  AppTheme.primaryColor.withValues(alpha: 0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFreeShipping
              ? Colors.teal.shade300.withValues(alpha: 0.4)
              : AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFreeShipping
                    ? Icons.local_shipping_rounded
                    : Icons.local_shipping_outlined,
                color: hasFreeShipping ? Colors.white : AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasFreeShipping
                      ? 'YOU HAVE UNLOCKED FREE EXPRESS DELIVERY! 🎉'
                      : 'Add ${currency.formatPrice(remaining)} more for FREE EXPRESS SHIPPING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: hasFreeShipping
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (!hasFreeShipping) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Cart Item Card ─────────────────────────────────────────────────────────
  Widget _buildCartItemCard(
    BuildContext context, {
    required dynamic item,
    required CartNotifier cartNotifier,
    required dynamic currency,
    required ResponsiveText responsive,
    required ColorScheme colorScheme,
    required bool isDark,
    bool grouped = false,
  }) {
    final product = item.product;
    final imageUrl = _resolveCartItemImage(item);

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Image Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 90,
              height: 110,
              color: colorScheme.outline.withValues(alpha: 0.05),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.fontSize14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        cartNotifier.removeFromCart(item.id);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Variants Badges (Size / Color)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.selectedSize != null &&
                        item.selectedSize!.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Size: ${item.selectedSize}',
                          style: TextStyle(
                            fontSize: responsive.fontSize10,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    if (item.selectedColor != null &&
                        item.selectedColor!.toString().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _parseColor(item.selectedColor),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.selectedColor}',
                              style: TextStyle(
                                fontSize: responsive.fontSize10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Price & Quantity Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        currency.formatPrice(product.price * item.quantity),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.fontSize15,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Quantity selector pill (- QTY +)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.outline.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded, size: 14),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              cartNotifier.updateQuantity(
                                item.id,
                                item.quantity - 1,
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${item.quantity}',
                              style: TextStyle(
                                fontSize: responsive.fontSize12,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded, size: 14),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              cartNotifier.updateQuantity(
                                item.id,
                                item.quantity + 1,
                              );
                            },
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
    );

    if (grouped) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: content,
    );
  }

  // ── Gift Wrapping Card ─────────────────────────────────────────────────────
  Widget _buildGiftWrappingCard(
    BuildContext context,
    ResponsiveText responsive,
    ColorScheme colorScheme,
    bool isDark,
    dynamic currency, {
    required bool isGiftWrapped,
    required double giftWrappingCost,
    required bool isEnabled,
  }) {
    if (!isEnabled) return const SizedBox.shrink();

    return _CartGroupedCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.card_giftcard_rounded,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gift wrapping',
                    style: TextStyle(
                      fontSize: responsive.fontSize13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)?.giftWrappingDesc ??
                        'Premium boxed wrap (${currency.formatPrice(giftWrappingCost)})',
                    style: TextStyle(
                      fontSize: responsive.fontSize11,
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isGiftWrapped,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (val) {
                HapticFeedback.lightImpact();
                ref.read(isGiftWrappedProvider.notifier).toggle(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Order Summary Card (Redesigned Luxury UI) ─────────────────────────────
  Widget _buildOrderSummaryCard(
    BuildContext context, {
    required ResponsiveText responsive,
    required ColorScheme colorScheme,
    required bool isDark,
    required dynamic currency,
    required double subtotal,
    required double shipping,
    required double tax,
    required bool hasInclusive,
    required double giftCost,
    required double totalAmount,
    required String orderSummaryText,
    required String subtotalText,
    required String shippingText,
    required String taxPercentText,
    required String totalText,
    List<CartItemModel>? cartItems,
  }) {
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final double couponDiscount = ref
        .read(appliedCouponProvider.notifier)
        .calculateDiscount(subtotal);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.2)
              : AppTheme.primaryColor.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(
              alpha: isDark ? 0.08 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    orderSummaryText.toUpperCase(),
                    style: TextStyle(
                      fontSize: responsive.fontSize12,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Color(0xFF10B981),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'SECURE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Itemized Product Price Breakdown Inside Card
          if (cartItems != null && cartItems.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: cartItems.map((item) {
                  final itemTotal = item.product.price * item.quantity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _resolveCartItemImage(item),
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 36,
                              height: 36,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: responsive.fontSize12,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.quantity} × ${currency.formatPrice(item.product.price)}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currency.formatPrice(itemTotal),
                          style: TextStyle(
                            fontSize: responsive.fontSize12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Breakdown Rows
          _buildSummaryRow(
            subtotalText,
            currency.formatPrice(subtotal),
            responsive,
            colorScheme,
          ),
          const SizedBox(height: 12),

          _buildSummaryRow(
            shippingText,
            shipping > 0 ? currency.formatPrice(shipping) : 'FREE',
            responsive,
            colorScheme,
            valueWidget: shipping == 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FREE SHIPPING 🎉',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          if (couponDiscount > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Coupon Discount (${appliedCoupon?.code ?? ""})',
              '-${currency.formatPrice(couponDiscount)}',
              responsive,
              colorScheme,
            ),
          ],

          if (ref.watch(cartProvider.notifier).taxBreakdown.length > 1) ...[
            for (final item in ref.watch(cartProvider.notifier).taxBreakdown) ...[
              const SizedBox(height: 6),
              _buildSummaryRow(
                item['name'] as String,
                currency.formatPrice(item['taxAmount'] as double),
                responsive,
                colorScheme,
              ),
            ],
          ] else if (ref.watch(cartProvider.notifier).taxBreakdown.isNotEmpty) ...[
            _buildSummaryRow(
              ref.watch(cartProvider.notifier).taxBreakdown.first['name'] as String,
              currency.formatPrice(
                (ref.watch(cartProvider.notifier).taxBreakdown.first['taxAmount'] as double?) ?? tax,
              ),
              responsive,
              colorScheme,
            ),
          ] else ...[
            _buildSummaryRow(
              'Taxes',
              currency.formatPrice(tax),
              responsive,
              colorScheme,
            ),
          ],

          if (giftCost > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Gift Wrapping',
              currency.formatPrice(giftCost),
              responsive,
              colorScheme,
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1),
          ),

          // Luxury Grand Total Pill Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  AppTheme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.02),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalText.toUpperCase(),
                      style: TextStyle(
                        fontSize: responsive.fontSize11,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      hasInclusive
                          ? 'Taxes & charges included'
                          : 'Final Order Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Text(
                  currency.formatPrice(totalAmount),
                  style: TextStyle(
                    fontSize: responsive.fontSize20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ResponsiveText responsive,
    ColorScheme colorScheme, {
    bool isTotal = false,
    bool isInfo = false,
    Widget? valueWidget,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize15 : responsive.fontSize13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
            color: isInfo
                ? Colors.grey.shade500
                : (isTotal
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.7)),
            fontStyle: isInfo ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        valueWidget ??
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal
                    ? responsive.fontSize18
                    : responsive.fontSize13,
                fontWeight: isTotal
                    ? FontWeight.w900
                    : (isInfo ? FontWeight.w400 : FontWeight.bold),
                color:
                    valueColor ??
                    (isTotal
                        ? AppTheme.primaryColor
                        : (isInfo
                              ? Colors.grey.shade500
                              : colorScheme.onSurface)),
                fontStyle: isInfo ? FontStyle.italic : FontStyle.normal,
              ),
            ),
      ],
    );
  }
}

class _CartSectionTitle extends StatelessWidget {
  const _CartSectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    return Padding(
      padding: EdgeInsets.only(left: responsive.spacing(4)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: responsive.fontSize10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

class _CartGroupedCard extends StatelessWidget {
  const _CartGroupedCard({this.child, this.children});

  final Widget? child;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.35)
              : colorScheme.outline,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child ?? Column(children: children ?? const []),
    );
  }
}
