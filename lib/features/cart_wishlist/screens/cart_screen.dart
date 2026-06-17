import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import 'package:hopscotch/features/cart_wishlist/repositories/cart_wishlist_repository.dart';
import '../../../core/widgets/state_widgets.dart';

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

    final double subtotal = cartNotifier.subtotal;
    final double shipping = 150.00;
    final double tax = subtotal * 0.08;
    final double giftCost = _includeGiftWrapping ? _giftWrappingCost : 0.0;
    final double totalAmount = subtotal + shipping + tax + giftCost;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'YOUR BAG',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        actions: [
          if (cart.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceL),
              child: TextButton(
                onPressed: () => cartNotifier.clearCart(),
                child: Text(
                  'CLEAR',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
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
              title: 'Your Bag is Empty',
              description: 'You haven\'t added any garments to your luxury bag yet. Browse our Collections to begin.',
              buttonText: 'Shop New Arrivals',
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
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL, vertical: AppTheme.spaceM),
                        child: Text(
                          '${cart.length} ITEM${cart.length > 1 ? 'S' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
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
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                        itemCount: cart.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spaceL),
                        itemBuilder: (context, index) {
                          final item = cart[index];
                          final product = item.product;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusL),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.spaceL),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Image
                                  GestureDetector(
                                    onTap: () => context.push('/product/${product.id}?heroTagPrefix=cart'),
                                    child: Hero(
                                      tag: 'cart_product_image_${product.id}',
                                      child: Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                          image: DecorationImage(
                                            image: NetworkImage(product.imageUrl),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spaceL),

                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Category & Remove
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              product.subcategory.toUpperCase(),
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => cartNotifier.removeFromCart(item.id),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 20,
                                                color: AppTheme.textLightColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppTheme.spaceS),

                                        // Product Name
                                        Text(
                                          product.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.playfairDisplay(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.spaceS),

                                        // Size & Color
                                        Row(
                                          children: [
                                            if (item.selectedSize != null) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppTheme.spaceS,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  item.selectedSize!,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppTheme.spaceS),
                                            ],
                                            if (item.selectedColor != null) ...[
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: _parseColor(item.selectedColor),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.1),
                                                      blurRadius: 4,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: AppTheme.spaceM),

                                        // Price & Quantity
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '₹${(product.price * item.quantity).toStringAsFixed(0)}',
                                              style: GoogleFonts.playfairDisplay(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQtyButton(
                                                    icon: Icons.remove_rounded,
                                                    onTap: () => cartNotifier.updateQuantity(item.id, item.quantity - 1),
                                                  ),
                                                  SizedBox(
                                                    width: 40,
                                                    child: Text(
                                                      item.quantity.toString(),
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.textPrimaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildQtyButton(
                                                    icon: Icons.add_rounded,
                                                    onTap: () => cartNotifier.updateQuantity(item.id, item.quantity + 1),
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
                      const SizedBox(height: AppTheme.spaceXL),

                      // Gift Wrapping
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceL),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: const Icon(
                                  Icons.card_giftcard_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spaceL),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gift Wrapping',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Premium boxed wrap with note card',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
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
                                activeColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXL),

                      // Order Summary
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
                        child: Container(
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusL),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORDER SUMMARY',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondaryColor,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(0)}'),
                              const SizedBox(height: AppTheme.spaceS),
                              _buildSummaryRow('Shipping', '₹${shipping.toStringAsFixed(0)}'),
                              const SizedBox(height: AppTheme.spaceS),
                              _buildSummaryRow('Tax (8%)', '₹${tax.toStringAsFixed(0)}'),
                              if (_includeGiftWrapping) ...[
                                const SizedBox(height: AppTheme.spaceS),
                                _buildSummaryRow('Gift Wrapping', '₹${_giftWrappingCost.toStringAsFixed(0)}'),
                              ],
                              const Divider(height: AppTheme.spaceXL),
                              _buildSummaryRow('Total', '₹${totalAmount.toStringAsFixed(0)}', isTotal: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXXL),
                    ],
                  ),
                ),

                // Bottom Panel
                Positioned(
                  bottom: 25,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spaceXL).copyWith(bottom: 40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
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
                                  'TOTAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondaryColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spaceL),
                            GestureDetector(
                              onTap: () => context.push('/checkout'),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: Center(
                                  child: Text(
                                    'PROCEED TO CHECKOUT',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
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

  Widget _buildQtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppTheme.textPrimaryColor),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
