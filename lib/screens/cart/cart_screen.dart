import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/constants/app_colors.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/widgets/state_widgets.dart';
import 'package:hopscotch/l10n/app_localizations.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/constants/app_urls.dart';
import 'package:hopscotch/utils/navigation_utils.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _includeGiftWrapping = false;
  final double _giftWrappingCost = 250.00;

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.trim().isEmpty) return Colors.grey;
    final str = colorStr.trim().toLowerCase();
    const colorMap = <String, Color>{
      'black': Colors.black,
      'white': Colors.white,
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'navy': Color(0xFF000080),
      'navy blue': Color(0xFF000080),
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
      'silver': Color(0xFFC0C0C0),
      'maroon': Color(0xFF800000),
      'beige': Color(0xFFF5F5DC),
      'olive': Color(0xFF808000),
      'coral': Color(0xFFFF7F50),
      'indigo': Color(0xFF3F51B5),
      'khaki': Color(0xFFC3B091),
      'magenta': Color(0xFFE91E63),
    };

    if (colorMap.containsKey(str)) {
      return colorMap[str]!;
    }

    try {
      String hex = colorStr.replaceAll('#', '').replaceAll('0x', '').trim();
      if (hex.length == 3) {
        hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      }
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
    } catch (_) {}

    return Colors.teal;
  }

  String _resolveCartItemImage(dynamic item) {
    final product = item.product;
    final allImages = [
      if (product.imageUrl.isNotEmpty) product.imageUrl as String,
      ...List<String>.from(product.additionalImages ?? []),
    ];

    if (item.selectedColor != null && item.selectedColor!.toString().trim().isNotEmpty) {
      final colorLower = item.selectedColor!.toString().trim().toLowerCase();

      if (product.variants != null) {
        for (final v in product.variants) {
          if (v.color?.toLowerCase() == colorLower && v.imageUrl != null && v.imageUrl!.isNotEmpty) {
            return v.imageUrl!;
          }
        }
      }

      final matchedImage = allImages.firstWhere(
        (url) => url.toLowerCase().contains(colorLower),
        orElse: () => '',
      );
      if (matchedImage.isNotEmpty) return matchedImage;

      final colorIdx = (product.colors as List).indexWhere((c) => c.toString().toLowerCase() == colorLower);
      if (colorIdx >= 0 && colorIdx < allImages.length) {
        return allImages[colorIdx];
      }
    }

    return product.imageUrl;
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

    final double subtotal = cart.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    const double shipping = 150.00;
    final double tax = cartNotifier.taxAmount;
    final double giftCost = _includeGiftWrapping ? _giftWrappingCost : 0.0;
    final double totalAmount = subtotal + shipping + tax + giftCost;

    final yourBagTitle = l10n?.yourBag ?? 'Your Bag';
    final clearText = l10n?.clear ?? 'Clear';
    final bagEmptyTitle = l10n?.bagEmpty ?? 'Your Shopping Bag is Empty';
    final bagEmptyDesc = l10n?.bagEmptyDescription ?? 'Explore our latest collections and add your favorite items.';
    final shopNewArrivalsText = l10n?.shopNewArrivals ?? 'Shop New Arrivals';
    final itemsText = l10n?.items ?? 'Items';
    final giftWrappingText = l10n?.giftWrapping ?? 'Gift Wrapping';
    final giftWrappingDescText = l10n?.giftWrappingDesc ?? 'Add a personalized message & luxury gift box';
    final orderSummaryText = l10n?.orderSummary ?? 'Order Summary';
    final subtotalText = l10n?.subtotal ?? 'Subtotal';
    final shippingText = l10n?.shipping ?? 'Shipping';
    final taxPercentText = l10n?.taxPercent ?? 'Estimated Tax';
    final totalText = l10n?.total ?? 'Total';
    final totalLabelText = l10n?.totalLabel ?? 'Total';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          yourBagTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: responsive.fontSize20,
            color: colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                right: responsive.spacing(AppTheme.spaceM),
              ),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  cartNotifier.clearCart();
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: Text(
                  clearText,
                  style: TextStyle(
                    fontSize: responsive.fontSize12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: bagEmptyTitle,
              description: bagEmptyDesc,
              buttonText: shopNewArrivalsText,
              onButtonPressed: () => context.go('/'),
            )
          : Stack(
              children: [
                // Scrollable content area
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: responsive.spacing(AppTheme.spaceL),
                      right: responsive.spacing(AppTheme.spaceL),
                      top: responsive.spacing(AppTheme.spaceS),
                      bottom: responsive.spacing(200), // Height for sticky bottom CTA
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Items Count Badge Header
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined, size: 14, color: colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                '${cart.length} ${itemsText.toLowerCase()}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cart Items List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cart.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            final product = item.product;

                            return Dismissible(
                              key: Key('cart_item_${item.id}_$index'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                HapticFeedback.mediumImpact();
                                return true;
                              },
                              onDismissed: (direction) {
                                cartNotifier.removeFromCart(item.id);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 24),
                                decoration: BoxDecoration(
                                  color: colorScheme.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 28),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Remove',
                                      style: TextStyle(
                                        color: colorScheme.error,
                                        fontSize: responsive.fontSize10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product Image Wrapper
                                      GestureDetector(
                                        onTap: () => safeNavigate(
                                          context,
                                          '/product/${product.id}?heroTagPrefix=cart_$index',
                                        ),
                                        child: Hero(
                                          tag: 'cart_${index}_product_image_${product.id}',
                                          child: Container(
                                            width: responsive.spacing(90),
                                            height: responsive.spacing(110),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              color: colorScheme.outline.withValues(alpha: 0.05),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                               child: () {
                                                 final rawUrl = _resolveCartItemImage(item);
                                                 final resolvedUrl = AppUrls.resolveUrl(rawUrl);
                                                 if (resolvedUrl.isEmpty) {
                                                   return Container(
                                                     color: colorScheme.outline.withValues(alpha: 0.1),
                                                     child: Center(
                                                       child: Icon(
                                                         Icons.image_not_supported_outlined,
                                                         color: colorScheme.primary.withValues(alpha: 0.5),
                                                         size: 24,
                                                       ),
                                                     ),
                                                   );
                                                 }
                                                 return Image.network(
                                                   resolvedUrl,
                                                   fit: BoxFit.cover,
                                                   errorBuilder: (context, error, stackTrace) {
                                                     return Container(
                                                       color: colorScheme.outline.withValues(alpha: 0.1),
                                                       child: Center(
                                                         child: Icon(
                                                           Icons.image_not_supported_outlined,
                                                           color: colorScheme.primary.withValues(alpha: 0.5),
                                                           size: 24,
                                                         ),
                                                       ),
                                                     );
                                                   },
                                                 );
                                               }(),
                                             ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Product Details & Quantity Adjuster
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Category tag
                                            Text(
                                              (product.subcategory.isEmpty ? 'Collections' : product.subcategory).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: responsive.fontSize10,
                                                fontWeight: FontWeight.w800,
                                                color: colorScheme.primary,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Title
                                            Text(
                                              product.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: responsive.fontSize14,
                                                color: colorScheme.onSurface,
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 8),

                                            // Options (Size & Color)
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              children: [
                                                if (item.selectedSize != null && item.selectedSize!.trim().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: colorScheme.primary.withValues(alpha: 0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Size: ${item.selectedSize}',
                                                      style: TextStyle(
                                                        fontSize: responsive.fontSize11,
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                if (item.selectedColor != null && item.selectedColor!.trim().isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.outline.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                      border: Border.all(
                                                        color: colorScheme.outline.withValues(alpha: 0.2),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 12,
                                                          height: 12,
                                                          decoration: BoxDecoration(
                                                            color: _parseColor(item.selectedColor),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: Colors.grey.shade400,
                                                              width: 0.8,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          item.selectedColor!,
                                                          style: TextStyle(
                                                            fontSize: responsive.fontSize11,
                                                            fontWeight: FontWeight.w600,
                                                            color: colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Price & Stepper row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  currency.formatPrice(product.price * item.quantity),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: responsive.fontSize15,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                                Container(
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.outline.withValues(alpha: 0.06),
                                                    borderRadius: BorderRadius.circular(30),
                                                    border: Border.all(
                                                      color: colorScheme.outline.withValues(alpha: 0.1),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      _buildStepperButton(
                                                        icon: Icons.remove_rounded,
                                                        onPressed: () {
                                                          HapticFeedback.lightImpact();
                                                          cartNotifier.updateQuantity(item.id, item.quantity - 1);
                                                        },
                                                        colorScheme: colorScheme,
                                                      ),
                                                      SizedBox(
                                                        width: 28,
                                                        child: Text(
                                                          item.quantity.toString(),
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: responsive.fontSize13,
                                                            fontWeight: FontWeight.bold,
                                                            color: colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                      _buildStepperButton(
                                                        icon: Icons.add_rounded,
                                                        onPressed: () {
                                                          HapticFeedback.lightImpact();
                                                          cartNotifier.updateQuantity(item.id, item.quantity + 1);
                                                        },
                                                        colorScheme: colorScheme,
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
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Gift Wrapping Toggle
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.card_giftcard_rounded,
                                  color: colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      giftWrappingText,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize13,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      giftWrappingDescText,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize10,
                                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Switch(
                                value: _includeGiftWrapping,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _includeGiftWrapping = val);
                                },
                                activeThumbColor: colorScheme.primary,
                                activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Summary Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: isDark ? 0.15 : 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderSummaryText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildSummaryRow(subtotalText, currency.formatPrice(subtotal), responsive, colorScheme),
                              const SizedBox(height: 10),
                              _buildSummaryRow(shippingText, currency.formatPrice(shipping), responsive, colorScheme),
                              const SizedBox(height: 10),
                              _buildSummaryRow(taxPercentText, currency.formatPrice(tax), responsive, colorScheme),
                              if (_includeGiftWrapping) ...[
                                const SizedBox(height: 10),
                                _buildSummaryRow(giftWrappingText, currency.formatPrice(_giftWrappingCost), responsive, colorScheme),
                              ],
                              const Divider(height: 24, thickness: 1),
                              _buildSummaryRow(
                                totalText,
                                currency.formatPrice(totalAmount),
                                responsive,
                                colorScheme,
                                isTotal: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating Premium Solid Bottom Panel
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.1),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Total summary detail
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalLabelText.toUpperCase(),
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currency.formatPrice(totalAmount),
                                style: TextStyle(
                                  fontSize: responsive.fontSize20,
                                  fontWeight: FontWeight.w900,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Checkout button
                        Expanded(
                          flex: 6,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              safeNavigate(context, '/checkout');
                            },
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 15),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SECURE CHECKOUT',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                                  ],
                                ),
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

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ResponsiveText responsive,
    ColorScheme colorScheme, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize13 : responsive.fontSize12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize15 : responsive.fontSize12,
            fontWeight: FontWeight.w800,
            color: isTotal ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
