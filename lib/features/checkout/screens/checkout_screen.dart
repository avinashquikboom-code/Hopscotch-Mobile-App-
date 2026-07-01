import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_text.dart';
import 'package:hopscotch/features/cart_wishlist/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/features/checkout/repositories/order_repository.dart';
import '../../../core/widgets/custom_button.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();

  // Premium Credit Card fields & anims
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _cvvFocusNode = FocusNode();
  bool _isCardFlipped = false;

  String _selectedPayment = 'Credit Card'; // Credit Card, Apple Pay, PayPal
  bool _isPlacingOrder = false;
  String? _paymentProcessingStep;

  @override
  void initState() {
    super.initState();
    _cvvFocusNode.addListener(() {
      setState(() {
        _isCardFlipped = _cvvFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

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
    if (clean.isNotEmpty) {
      formatted += clean.substring(0, clean.length < 2 ? clean.length : 2);
      if (clean.length > 2) {
        formatted +=
            '/${clean.substring(2, clean.length < 4 ? clean.length : 4)}';
      }
    }
    if (formatted != _cardExpiryController.text) {
      _cardExpiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  Future<void> _handlePlaceOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;

    setState(() {
      _isPlacingOrder = true;
      _paymentProcessingStep = 'AUTHENTICATING BILLING KEY...';
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _paymentProcessingStep = 'RESERVING DESIGNER COUTURE...';
      });
    }
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final cartNotifier = ref.read(cartProvider.notifier);
      final address =
          '${_addressController.text}, ${_cityController.text}, ${_zipController.text}';

      final order = await ref
          .read(orderProvider.notifier)
          .placeOrder(
            items: cart,
            totalAmount: cartNotifier.totalAmount,
            address: address,
            paymentMethod: _selectedPayment,
          );

      if (mounted) {
        setState(() {
          _paymentProcessingStep = 'ASSIGNING COUTURE LOGISTICS... ✨';
        });
      }
      await Future.delayed(const Duration(milliseconds: 1000));

      // Clear the cart on successful checkout
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        context.go('/order-success?orderId=${order.id}');
      }
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
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'CHECKOUT',
            style: TextStyle(
              fontSize: responsive.fontSize18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Your cart is empty.',
            style: TextStyle(fontSize: responsive.fontSize14),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SECURE CHECKOUT',
          style: TextStyle(
            fontSize: responsive.fontSize18,
            fontWeight: FontWeight.bold,
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
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shipping Form
                  Text(
                    'Shipping Address',
                    style: TextStyle(
                      fontSize: responsive.fontSize18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Street Address',
                      prefixIcon: Icon(
                        Icons.home_outlined,
                        size: responsive.iconSize(20),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(
                              Icons.location_city_outlined,
                              size: responsive.iconSize(20),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'City is required'
                              : null,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(AppTheme.spaceL)),
                      Expanded(
                        child: TextFormField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'ZIP Code',
                            prefixIcon: Icon(
                              Icons.pin_drop_outlined,
                              size: responsive.iconSize(20),
                            ),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'ZIP required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(
                        Icons.phone_outlined,
                        size: responsive.iconSize(20),
                      ),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Phone number is required'
                        : null,
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                  // Payment Selection
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: responsive.fontSize18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  _buildPaymentOption('Credit Card', Icons.credit_card_rounded),

                  // Dynamic Flipping Credit Card Form Area
                  if (_selectedPayment == 'Credit Card') ...[
                    SizedBox(height: responsive.spacing(AppTheme.spaceL)),
                    _buildCreditCardInteractiveForm(),
                  ],

                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  _buildPaymentOption('Apple Pay', Icons.apple_rounded),
                  SizedBox(height: responsive.spacing(AppTheme.spaceM)),
                  _buildPaymentOption('PayPal', Icons.payment_rounded),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                  // Summary
                  Container(
                    padding: EdgeInsets.all(
                      responsive.spacing(AppTheme.spaceL),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      children: [
                        _buildPricingRow(
                          'Subtotal',
                          '₹${cartNotifier.subtotal.toStringAsFixed(2)}',
                        ),
                        SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                        _buildPricingRow('Elite Courier Shipping', '₹15.00'),
                        SizedBox(height: responsive.spacing(AppTheme.spaceS)),
                        _buildPricingRow(
                          'Estimated Tax',
                          '₹${(cartNotifier.subtotal * 0.08).toStringAsFixed(2)}',
                        ),
                        Divider(height: responsive.spacing(AppTheme.spaceL)),
                        _buildPricingRow(
                          'Order Total',
                          '₹${cartNotifier.totalAmount.toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),

                  // Submit Button
                  CustomButton(
                    text: 'PLACE SECURE ORDER',
                    onPressed: _handlePlaceOrder,
                    isLoading: _isPlacingOrder,
                  ),
                  SizedBox(height: responsive.spacing(AppTheme.spaceXL)),
                ],
              ),
            ),
          ),
          if (_isPlacingOrder)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.96),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: responsive.spacing(54),
                        height: responsive.spacing(54),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(AppTheme.spaceXXL)),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _paymentProcessingStep ??
                              'PROCESSING SECURE TRANSACTION...',
                          key: ValueKey(_paymentProcessingStep),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.fontSize14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String name, IconData icon) {
    final responsive = context.responsive;
    final isSelected = _selectedPayment == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPayment = name;
        });
      },
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.04)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: responsive.iconSize(24),
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor,
                ),
                SizedBox(width: responsive.spacing(AppTheme.spaceM)),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: responsive.fontSize14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: responsive.iconSize(20),
                color: AppTheme.primaryColor,
              )
            else
              Container(
                width: responsive.spacing(20),
                height: responsive.spacing(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.borderColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, String value, {bool isTotal = false}) {
    final responsive = context.responsive;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? AppTheme.textPrimaryColor
                : AppTheme.textSecondaryColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? responsive.fontSize15 : responsive.fontSize13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? responsive.fontSize16 : responsive.fontSize13,
          ),
        ),
      ],
    );
  }

  // Breathtaking 3D Interactive Card Layout
  Widget _buildCreditCardInteractiveForm() {
    final responsive = context.responsive;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceL)),
      decoration: BoxDecoration(
        color: AppTheme.borderColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // 3D Flipping Card
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOut,
            tween: Tween<double>(begin: 0.0, end: _isCardFlipped ? pi : 0.0),
            builder: (context, angle, child) {
              final isBack = angle >= pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012) // Perfect 3D perspective depth!
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: isBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: _buildCreditCardBack(),
                      )
                    : _buildCreditCardFront(),
              );
            },
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceXL)),

          // Inputs Form Fields
          TextFormField(
            controller: _cardNumberController,
            keyboardType: TextInputType.number,
            maxLength: 19,
            onChanged: _onCardNumberChanged,
            decoration: InputDecoration(
              labelText: 'Card Number',
              prefixIcon: Icon(
                Icons.credit_card,
                size: responsive.iconSize(20),
              ),
              counterText: '',
            ),
            validator: (value) {
              if (_selectedPayment != 'Credit Card') return null;
              if (value == null || value.trim().length < 15) {
                return 'Invalid credit card number';
              }
              return null;
            },
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          TextFormField(
            controller: _cardNameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              prefixIcon: Icon(
                Icons.person_outline,
                size: responsive.iconSize(20),
              ),
            ),
            validator: (value) {
              if (_selectedPayment != 'Credit Card') return null;
              if (value == null || value.trim().isEmpty) {
                return 'Cardholder name is required';
              }
              return null;
            },
          ),
          SizedBox(height: responsive.spacing(AppTheme.spaceL)),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _cardExpiryController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onChanged: _onExpiryChanged,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    prefixIcon: Icon(
                      Icons.calendar_today_outlined,
                      size: responsive.iconSize(20),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (_selectedPayment != 'Credit Card') return null;
                    if (value == null || !value.contains('/')) {
                      return 'Use MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: responsive.spacing(AppTheme.spaceL)),
              Expanded(
                child: TextFormField(
                  controller: _cardCvvController,
                  focusNode: _cvvFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: responsive.iconSize(20),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (_selectedPayment != 'Credit Card') return null;
                    if (value == null || value.trim().length < 3) {
                      return 'Invalid CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardFront() {
    final responsive = context.responsive;
    final number = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final name = _cardNameController.text.isEmpty
        ? 'ARIA STERLING'
        : _cardNameController.text.toUpperCase();
    final expiry = _cardExpiryController.text.isEmpty
        ? 'MM/YY'
        : _cardExpiryController.text;

    // Detect card brand (Visa = starts with 4, Mastercard = starts with 5)
    final isVisa = _cardNumberController.text.startsWith('4');
    final isMastercard = _cardNumberController.text.startsWith('5');

    return Container(
      height: responsive.spacing(190),
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(AppTheme.spaceXL)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D11), // Ultra-premium obsidian midnight black
            Color(0xFF242429), // Smooth carbon graphite black
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Premium Gold Metallic Contact Chip
              Container(
                width: responsive.spacing(42),
                height: responsive.spacing(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF7D070),
                      Color(0xFFC59F3E),
                      Color(0xFFF7D070),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Card brand / Signature branding
              Text(
                isVisa ? 'VISA' : (isMastercard ? 'MASTERCARD' : 'AURA ELITE'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: responsive.fontSize13,
                ),
              ),
            ],
          ),

          // Real-time Number Display
          Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.fontSize19,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),

          // Holder & Expiry details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARDHOLDER',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: responsive.fontSize8,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsive.fontSize12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: responsive.fontSize8,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    expiry,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsive.fontSize12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardBack() {
    final cvv = _cardCvvController.text.isEmpty
        ? '•••'
        : _cardCvvController.text;

    return Container(
      height: 190,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D0D11), // Midnight Black
            Color(0xFF1F1F24), // Charcoal Black
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Magnetic Strip
          Container(height: 38, color: Colors.black87, width: double.infinity),
          const SizedBox(height: AppTheme.spaceL),

          // Signature Panel with CVV block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: const BoxDecoration(color: Colors.white70),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 8),
                    child: const Text(
                      'AURA COUTURE MEMBER EXCLUSIVE',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 8,
                        color: Colors.black45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 50,
                  height: 38,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text(
                    cvv,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Holographic Seal Mock
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceXL),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withValues(alpha: 0.4),
                        Colors.teal.withValues(alpha: 0.4),
                        Colors.purple.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                const Text(
                  'Authorized Signature Only',
                  style: TextStyle(color: Colors.white30, fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
