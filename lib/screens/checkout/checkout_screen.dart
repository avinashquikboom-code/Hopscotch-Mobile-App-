import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/providers/currency_provider.dart';

// ---------------------------------------------------------------------------
// Country list (includes all 8 new countries)
// ---------------------------------------------------------------------------
const _kCountries = [
  'India', 'United States', 'United Kingdom', 'UAE (Dubai)',
  'Bahrain', 'Malaysia', 'Mauritius', 'Fiji', 'Guyana',
  'Suriname', 'Trinidad & Tobago', 'Australia', 'Canada',
  'Germany', 'France', 'Japan', 'Singapore', 'Saudi Arabia',
  'Qatar', 'Kuwait', 'Oman', 'South Africa', 'New Zealand',
];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Shipping controllers ────────────────────────────────────────────────
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedCountry = 'India';

  // ── Credit Card controllers ─────────────────────────────────────────────
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cvvFocusNode = FocusNode();
  bool _isCardFlipped = false;

  // ── Payment ─────────────────────────────────────────────────────────────
  String _selectedPayment = 'Razorpay';
  bool _isPlacingOrder = false;
  String? _paymentProcessingStep;

  // ── Razorpay ────────────────────────────────────────────────────────────
  late Razorpay _razorpay;
  static const String _razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID'; // Replace with actual key

  @override
  void initState() {
    super.initState();
    _cvvFocusNode.addListener(() {
      setState(() => _isCardFlipped = _cvvFocusNode.hasFocus);
    });

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cvvFocusNode.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay handlers ───────────────────────────────────────────────────
  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _paymentProcessingStep = 'PAYMENT CONFIRMED ✓');
    final cart = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final address =
        '${_firstNameController.text} ${_lastNameController.text}, '
        '${_addressController.text}, ${_cityController.text}, '
        '$_selectedCountry - ${_zipController.text}';
    try {
      final order = await ref.read(orderProvider.notifier).placeOrder(
            items: cart,
            totalAmount: cartNotifier.totalAmount,
            address: address,
            paymentMethod: 'Razorpay',
          );
      cartNotifier.clearCart();
      if (mounted) context.go('/order-success?orderId=${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order save failed: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPlacingOrder = false);
  }

  // ── Card formatting ─────────────────────────────────────────────────────
  void _onCardNumberChanged(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    var formatted = '';
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += clean[i];
    }
    if (formatted != _cardNumberController.text) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _onExpiryChanged(String value) {
    final clean = value.replaceAll(RegExp(r'\D'), '');
    var formatted = '';
    for (var i = 0; i < clean.length && i < 4; i++) {
      if (i == 2) formatted += '/';
      formatted += clean[i];
    }
    if (formatted != _cardExpiryController.text) {
      _cardExpiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  // ── Place order ─────────────────────────────────────────────────────────
  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    if (_selectedPayment == 'Razorpay') {
      _openRazorpay();
      return;
    }

    setState(() {
      _isPlacingOrder = true;
      _paymentProcessingStep = 'AUTHENTICATING BILLING KEY...';
    });
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() => _paymentProcessingStep = 'PROCESSING PAYMENT...');
    }
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      final address =
          '${_firstNameController.text} ${_lastNameController.text}, '
          '${_addressController.text}, ${_cityController.text}, '
          '$_selectedCountry - ${_zipController.text}';

      final order = await ref.read(orderProvider.notifier).placeOrder(
            items: cart,
            totalAmount: cartNotifier.totalAmount,
            address: address,
            paymentMethod: _selectedPayment,
          );

      if (mounted) {
        setState(() => _paymentProcessingStep = 'ORDER PLACED SUCCESSFULLY ✨');
      }
      await Future.delayed(const Duration(milliseconds: 1000));
      ref.read(cartProvider.notifier).clearCart();
      if (mounted) context.go('/order-success?orderId=${order.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _openRazorpay() {
    final cart = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final amountInPaise = (cartNotifier.totalAmount * 100).toInt();
    setState(() => _isPlacingOrder = true);

    final options = {
      'key': _razorpayKeyId,
      'amount': amountInPaise,
      'name': 'FCI Seller',
      'description': '${cart.length} item(s)',
      'prefill': {
        'contact': _phoneController.text,
        'email': '',
      },
      'theme': {'color': '#0d9488'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open Razorpay: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currency = ref.watch(currencyProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHECKOUT')),
        body: const Center(child: Text('Your cart is empty.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          'SECURE CHECKOUT',
          style: TextStyle(
            fontSize: responsive.fontSize16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, size: responsive.iconSize(24)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: AppTheme.primaryColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  'SSL SECURED',
                  style: TextStyle(
                    fontSize: responsive.fontSize10,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(responsive.spacing(16)).copyWith(bottom: 120),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SHIPPING ADDRESS ──────────────────────────────────
                  _sectionHeader(context, responsive, Icons.local_shipping_outlined, 'SHIPPING ADDRESS'),
                  _sectionCard(
                    context,
                    isDark,
                    colorScheme,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildField(responsive, _firstNameController, 'First Name', Icons.person_outline, validator: _required)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(responsive, _lastNameController, 'Last Name', Icons.person_outline, validator: _required)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildField(responsive, _addressController, 'Street Address', Icons.home_outlined, validator: _required),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildField(responsive, _cityController, 'City', Icons.location_city_outlined, validator: _required)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildField(responsive, _zipController, 'ZIP Code', Icons.pin_drop_outlined, keyboardType: TextInputType.number, validator: _required)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Country Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCountry,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          prefixIcon: Icon(Icons.flag_outlined, size: responsive.iconSize(20)),
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _kCountries
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(fontSize: responsive.fontSize14))))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCountry = val ?? 'India'),
                        validator: (v) => v == null || v.isEmpty ? 'Please select a country' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(responsive, _phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone, validator: _required),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── PAYMENT METHOD ────────────────────────────────────
                  _sectionHeader(context, responsive, Icons.payment_rounded, 'PAYMENT METHOD'),
                  _sectionCard(
                    context,
                    isDark,
                    colorScheme,
                    children: [
                      _buildPaymentOption(context, responsive, colorScheme, 'Razorpay', Icons.bolt_rounded, subtitle: 'UPI, Cards, Wallets & More', color: const Color(0xFF2F8FFF)),
                      const SizedBox(height: 12),
                      _buildPaymentOption(context, responsive, colorScheme, 'Credit Card', Icons.credit_card_rounded, subtitle: 'Visa, Mastercard, Amex'),
                      if (_selectedPayment == 'Credit Card') ...[
                        const SizedBox(height: 16),
                        _buildCreditCardInteractiveForm(responsive, colorScheme, isDark),
                      ],
                      const SizedBox(height: 12),
                      _buildPaymentOption(context, responsive, colorScheme, 'Cash on Delivery', Icons.money_rounded, subtitle: 'Pay when you receive'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── ORDER SUMMARY ─────────────────────────────────────
                  _sectionHeader(context, responsive, Icons.receipt_long_outlined, 'ORDER SUMMARY'),
                  _sectionCard(
                    context,
                    isDark,
                    colorScheme,
                    children: [
                      // Product thumbnails strip
                      if (cart.isNotEmpty) ...[
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: cart.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final img = cart[i].product.imageUrl;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(img, width: 56, height: 56, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: colorScheme.outline.withValues(alpha: 0.1))),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                      ],
                      _priceRow(responsive, colorScheme, 'Subtotal', currency.formatPrice(cartNotifier.subtotal)),
                      const SizedBox(height: 8),
                      _priceRow(responsive, colorScheme, 'Shipping', currency.formatPrice(150.00)),
                      const SizedBox(height: 8),
                      _priceRow(responsive, colorScheme, 'Tax (8%)', currency.formatPrice(cartNotifier.subtotal * 0.08)),
                      const Divider(height: 24),
                      _priceRow(responsive, colorScheme, 'Order Total', currency.formatPrice(cartNotifier.totalAmount), isTotal: true),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── STICKY CTA ──────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TOTAL', style: TextStyle(fontSize: responsive.fontSize10, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withValues(alpha: 0.5), letterSpacing: 1.5)),
                        Text(currency.formatPrice(cartNotifier.totalAmount), style: TextStyle(fontSize: responsive.fontSize20, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: GestureDetector(
                      onTap: _isPlacingOrder ? null : _handlePlaceOrder,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _isPlacingOrder
                              ? null
                              : const LinearGradient(
                                  colors: [Color(0xFF0d9488), Color(0xFF14b8a6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                          color: _isPlacingOrder ? AppTheme.primaryColor.withValues(alpha: 0.5) : null,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: _isPlacingOrder
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _paymentProcessingStep ?? 'Processing...',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  _selectedPayment == 'Razorpay' ? 'PAY WITH RAZORPAY' : 'PLACE ORDER',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
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

  // ── Helpers ─────────────────────────────────────────────────────────────

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  Widget _sectionHeader(BuildContext context, ResponsiveText responsive, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, bool isDark, ColorScheme colorScheme, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildField(
    ResponsiveText responsive,
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: responsive.fontSize14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: responsive.iconSize(18)),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _buildPaymentOption(
    BuildContext context,
    ResponsiveText responsive,
    ColorScheme colorScheme,
    String name,
    IconData icon, {
    String? subtitle,
    Color? color,
  }) {
    final isSelected = _selectedPayment == name;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppTheme.primaryColor).withValues(alpha: 0.06) : colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (color ?? AppTheme.primaryColor) : colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? (color ?? AppTheme.primaryColor) : colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: responsive.fontSize14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? (color ?? AppTheme.primaryColor) : colorScheme.onSurface)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(fontSize: responsive.fontSize11, color: colorScheme.onSurface.withValues(alpha: 0.5))),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? (color ?? AppTheme.primaryColor) : Colors.transparent,
                border: Border.all(color: isSelected ? (color ?? AppTheme.primaryColor) : colorScheme.outline.withValues(alpha: 0.4), width: 2),
              ),
              child: isSelected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(ResponsiveText responsive, ColorScheme colorScheme, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? responsive.fontSize14 : responsive.fontSize13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w500, color: isTotal ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6))),
        Text(value, style: TextStyle(fontSize: isTotal ? responsive.fontSize16 : responsive.fontSize13, fontWeight: isTotal ? FontWeight.bold : FontWeight.w600, color: isTotal ? AppTheme.primaryColor : colorScheme.onSurface)),
      ],
    );
  }

  // ── 3D Credit Card ───────────────────────────────────────────────────────
  Widget _buildCreditCardInteractiveForm(ResponsiveText responsive, ColorScheme colorScheme, bool isDark) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0.0, end: _isCardFlipped ? pi : 0.0),
          builder: (context, angle, child) {
            final isBack = angle >= pi / 2;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              alignment: Alignment.center,
              child: isBack
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildCreditCardBack(responsive),
                    )
                  : _buildCreditCardFront(responsive),
            );
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          maxLength: 19,
          onChanged: _onCardNumberChanged,
          decoration: InputDecoration(
            labelText: 'Card Number',
            counterText: '',
            prefixIcon: const Icon(Icons.credit_card),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Card number required' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _cardNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cardExpiryController,
                keyboardType: TextInputType.number,
                maxLength: 5,
                onChanged: _onExpiryChanged,
                decoration: InputDecoration(
                  labelText: 'MM/YY',
                  counterText: '',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _cardCvvController,
                focusNode: _cvvFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  counterText: '',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCreditCardFront(ResponsiveText responsive) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0d9488), Color(0xFF14b8a6), Color(0xFF5eead4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.contactless_rounded, color: Colors.white70, size: 28),
            Text('VISA', style: TextStyle(color: Colors.white, fontSize: responsive.fontSize18, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ]),
          const Spacer(),
          Text(
            _cardNumberController.text.isEmpty ? '**** **** **** ****' : _cardNumberController.text,
            style: TextStyle(color: Colors.white, fontSize: responsive.fontSize18, fontWeight: FontWeight.bold, letterSpacing: 2.5),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CARDHOLDER', style: TextStyle(color: Colors.white54, fontSize: responsive.fontSize10, letterSpacing: 1)),
              Text(
                _cardNameController.text.isEmpty ? 'YOUR NAME' : _cardNameController.text.toUpperCase(),
                style: TextStyle(color: Colors.white, fontSize: responsive.fontSize12, fontWeight: FontWeight.bold),
              ),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EXPIRES', style: TextStyle(color: Colors.white54, fontSize: responsive.fontSize10, letterSpacing: 1)),
              Text(
                _cardExpiryController.text.isEmpty ? 'MM/YY' : _cardExpiryController.text,
                style: TextStyle(color: Colors.white, fontSize: responsive.fontSize12, fontWeight: FontWeight.bold),
              ),
            ]),
          ]),
        ],
      ),
    );
  }

  Widget _buildCreditCardBack(ResponsiveText responsive) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0d9488), Color(0xFF0f766e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(height: 30),
          Container(height: 48, color: Colors.black.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    _cardCvvController.text.isEmpty ? 'CVV' : _cardCvvController.text,
                    style: TextStyle(fontSize: responsive.fontSize14, fontWeight: FontWeight.bold, color: Colors.black87),
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
