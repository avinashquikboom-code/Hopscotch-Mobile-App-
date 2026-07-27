import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:hopscotch/theme/app_theme.dart';
import 'package:hopscotch/utils/responsive_text.dart';
import 'package:hopscotch/repositories/cart_wishlist_repository.dart';
import 'package:hopscotch/repositories/order_repository.dart';
import 'package:hopscotch/repositories/notification_repository.dart';
import 'package:hopscotch/providers/currency_provider.dart';
import 'package:hopscotch/repositories/config_repository.dart';
import 'package:hopscotch/repositories/payment_repository.dart';
import 'package:hopscotch/repositories/address_repository.dart';
import 'package:hopscotch/repositories/profile_repository.dart';
import 'package:hopscotch/providers/coupon_provider.dart';
import 'package:hopscotch/providers/gift_wrap_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

const List<String> _kDefaultCountries = [
  'India',
  'United States',
  'United Kingdom',
  'UAE (Dubai)',
  'Bahrain',
  'Malaysia',
  'Mauritius',
  'Fiji',
  'Guyana',
  'Suriname',
  'Trinidad & Tobago',
  'Australia',
  'Canada',
  'Germany',
  'France',
  'Japan',
  'Singapore',
  'Saudi Arabia',
  'Qatar',
  'Kuwait',
  'Oman',
  'South Africa',
  'New Zealand',
  'Netherlands',
  'Spain',
  'Italy',
  'Switzerland',
  'China',
  'Brazil',
  'Mexico',
];

String _matchCountryName(
  String rawCountry,
  List<String> availableCountries, {
  Map<String, String>? isoMap,
}) {
  if (rawCountry.trim().isEmpty) {
    return availableCountries.isNotEmpty ? availableCountries.first : 'India';
  }
  final trimmed = rawCountry.trim();

  // 1. Exact match
  if (availableCountries.contains(trimmed)) return trimmed;

  // 2. Case-insensitive match
  for (final c in availableCountries) {
    if (c.toLowerCase() == trimmed.toLowerCase()) return c;
  }

  // 3. ISO Code mapping dynamically passed from API
  if (isoMap != null && isoMap.containsKey(trimmed.toUpperCase())) {
    final mappedName = isoMap[trimmed.toUpperCase()]!;
    for (final c in availableCountries) {
      if (c.toLowerCase() == mappedName.toLowerCase() ||
          c.contains(mappedName)) {
        return c;
      }
    }
  }

  return availableCountries.contains('India')
      ? 'India'
      : (availableCountries.isNotEmpty ? availableCountries.first : 'India');
}

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

  // ── Payment ─────────────────────────────────────────────────────────────
  String _selectedPayment = 'Razorpay';
  bool _isPlacingOrder = false;
  String? _paymentProcessingStep;

  // ── Razorpay ────────────────────────────────────────────────────────────
  late Razorpay _razorpay;
  Timer? _razorpayTimeoutTimer;

  String? _selectedAddressId;
  bool _showItemSummary = false;

  void _cancelRazorpayTimeout() {
    if (_razorpayTimeoutTimer != null) {
      dev.log('Cancelling active Razorpay timeout timer', name: 'Razorpay');
      _razorpayTimeoutTimer?.cancel();
      _razorpayTimeoutTimer = null;
    }
  }

  void _startRazorpayTimeout() {
    _cancelRazorpayTimeout();
    dev.log('Starting 15s Razorpay timeout timer', name: 'Razorpay');
    _razorpayTimeoutTimer = Timer(const Duration(seconds: 15), () {
      dev.log('Razorpay timeout triggered after 15 seconds', name: 'Razorpay');
      if (mounted && _isPlacingOrder) {
        setState(() {
          _isPlacingOrder = false;
          _paymentProcessingStep = null;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Payment was not completed. You can try again.',
            ),
            backgroundColor: Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'RETRY PAYMENT',
              textColor: Colors.white,
              onPressed: () {
                _openRazorpay();
              },
            ),
          ),
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initRazorpay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillDefaultAddress();
    });
  }

  void _autoFillDefaultAddress() {
    final addresses = ref.read(addressNotifierProvider);
    if (addresses.isEmpty) return;

    final defaultAddr = addresses.firstWhere(
      (a) => a.isDefault,
      orElse: () => addresses.first,
    );

    final parts = defaultAddr.fullName.trim().split(' ');
    setState(() {
      _selectedAddressId = defaultAddr.id;
      if (_firstNameController.text.isEmpty) {
        _firstNameController.text = parts.first;
      }
      if (_lastNameController.text.isEmpty) {
        _lastNameController.text = parts.length > 1
            ? parts.sublist(1).join(' ')
            : '';
      }
      if (_addressController.text.isEmpty) {
        _addressController.text =
            defaultAddr.addressLine1 +
            (defaultAddr.addressLine2.isNotEmpty
                ? ', ${defaultAddr.addressLine2}'
                : '');
      }
      if (_cityController.text.isEmpty) {
        _cityController.text = defaultAddr.city;
      }
      if (_zipController.text.isEmpty) {
        _zipController.text = defaultAddr.pincode;
      }
      if (_phoneController.text.isEmpty) {
        _phoneController.text = defaultAddr.phone;
      }
      if (defaultAddr.country.isNotEmpty) {
        final countriesData = ref.read(apiCountriesProvider).value;
        final apiList = countriesData
            ?.map((c) => c['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        final countriesList = (apiList != null && apiList.isNotEmpty)
            ? apiList
            : _kDefaultCountries;
        final apiIsoMap = <String, String>{};
        if (countriesData != null) {
          for (final c in countriesData) {
            final code = c['code']?.toString().toUpperCase();
            final name = c['name']?.toString();
            if (code != null &&
                code.isNotEmpty &&
                name != null &&
                name.isNotEmpty) {
              apiIsoMap[code] = name;
            }
          }
        }
        _selectedCountry = _matchCountryName(
          defaultAddr.country,
          countriesList,
          isoMap: apiIsoMap,
        );
      }
    });
  }

  void _initRazorpay() {
    dev.log('Initializing Razorpay SDK event listeners', name: 'Razorpay');
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      dev.log(
        'Razorpay SDK event listeners registered successfully',
        name: 'Razorpay',
      );
    } catch (e, stackTrace) {
      dev.log(
        'Error initializing Razorpay SDK plugin: $e',
        name: 'Razorpay',
        error: e,
        stackTrace: stackTrace,
      );
      debugPrint('Razorpay plugin initialization notice: $e');
    }
  }

  @override
  void dispose() {
    _cancelRazorpayTimeout();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    try {
      _razorpay.clear();
      dev.log('Razorpay instance cleared on widget dispose', name: 'Razorpay');
    } catch (_) {}
    super.dispose();
  }

  double _calculateFinalTotalPayable() {
    final cart = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final giftWrapConfig =
        ref.read(giftWrapConfigProvider).valueOrNull ??
        const GiftWrapConfig(enabled: true, charge: 49.0);
    final isGiftWrapped = ref.read(isGiftWrappedProvider);

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

    final giftWrapCharge = (isGiftWrapped && giftWrapConfig.enabled)
        ? giftWrappingCost
        : 0.0;
    final discount = ref
        .read(appliedCouponProvider.notifier)
        .calculateDiscount(cartNotifier.subtotal);
    final rawTotalPayable =
        (cartNotifier.subtotal -
                discount +
                cartNotifier.shippingFee +
                cartNotifier.exclusiveTaxAmount +
                giftWrapCharge)
            .clamp(0.0, double.infinity);
    return (rawTotalPayable * 100.0).roundToDouble() / 100.0;
  }

  // ── Razorpay handlers ───────────────────────────────────────────────────
  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    dev.log(
      'Razorpay payment success event received: paymentId=${response.paymentId}, orderId=${response.orderId}, signature=${response.signature}',
      name: 'Razorpay',
    );
    _cancelRazorpayTimeout();

    final cart = ref.read(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final address =
        '${_firstNameController.text} ${_lastNameController.text}, '
        '${_addressController.text}, ${_cityController.text}, '
        '$_selectedCountry - ${_zipController.text}';

    try {
      if (response.orderId != null &&
          response.paymentId != null &&
          response.signature != null) {
        setState(
          () => _paymentProcessingStep = 'VERIFYING PAYMENT SIGNATURE...',
        );
        dev.log(
          'Verifying Razorpay payment signature via backend API',
          name: 'Razorpay',
        );
        await ref
            .read(paymentRepositoryProvider)
            .verifyRazorpayPayment(
              razorpayOrderId: response.orderId!,
              razorpayPaymentId: response.paymentId!,
              razorpaySignature: response.signature!,
            );
      }

      setState(() => _paymentProcessingStep = 'PLACING ORDER...');
      dev.log(
        'Placing order on backend with Razorpay payment method',
        name: 'Razorpay',
      );
      final isGiftWrapped = ref.read(isGiftWrappedProvider);
      final finalTotal = _calculateFinalTotalPayable();
      final order = await ref
          .read(orderProvider.notifier)
          .placeOrder(
            items: cart,
            subtotal: cartNotifier.subtotal,
            shippingFee: cartNotifier.shippingFee,
            taxAmount: cartNotifier.taxAmount,
            totalAmount: finalTotal,
            address: address,
            addressId: (int.tryParse(_selectedAddressId ?? '') != null)
                ? _selectedAddressId
                : null,
            paymentMethod: 'Razorpay',
            giftWrap: isGiftWrapped,
          );
      dev.log(
        'Order placed successfully via Razorpay: #${order.id}',
        name: 'Razorpay',
      );
      cartNotifier.clearCart();
      if (mounted) context.go('/order-success?orderId=${order.id}');
    } catch (e, stackTrace) {
      dev.log(
        'Error completing order after Razorpay success: $e',
        name: 'Razorpay',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: $e'),
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
    dev.log(
      'EVENT_PAYMENT_ERROR received: code=${response.code}, message=${response.message}',
      name: 'Razorpay',
      error: response.message,
    );
    _cancelRazorpayTimeout();
    if (mounted) {
      setState(() => _isPlacingOrder = false);
      final msg = response.code == Razorpay.PAYMENT_CANCELLED
          ? 'Payment cancelled by user.'
          : 'Payment failed: ${response.message ?? "Transaction declined"}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: response.code == Razorpay.PAYMENT_CANCELLED
              ? Colors.orange.shade800
              : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    dev.log(
      'EVENT_EXTERNAL_WALLET received: walletName=${response.walletName}',
      name: 'Razorpay',
    );
    _cancelRazorpayTimeout();
    if (mounted) {
      setState(() => _isPlacingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Redirected to external wallet: ${response.walletName ?? "Wallet"}',
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openRazorpay() async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      dev.log('Cart is empty, aborting Razorpay checkout', name: 'Razorpay');
      return;
    }

    final cartNotifier = ref.read(cartProvider.notifier);
    final giftWrapConfig =
        ref.read(giftWrapConfigProvider).valueOrNull ??
        const GiftWrapConfig(enabled: true, charge: 49.0);
    final isGiftWrapped = ref.read(isGiftWrappedProvider);

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

    final giftWrapCharge = (isGiftWrapped && giftWrapConfig.enabled)
        ? giftWrappingCost
        : 0.0;
    final appliedCoupon = ref.read(appliedCouponProvider);
    final discount = ref
        .read(appliedCouponProvider.notifier)
        .calculateDiscount(cartNotifier.subtotal);
    final rawTotalPayable =
        (cartNotifier.subtotal -
        discount +
        cartNotifier.shippingFee +
        cartNotifier.exclusiveTaxAmount +
        giftWrapCharge);
    final totalAmount = (rawTotalPayable * 100.0).roundToDouble() / 100.0;

    dev.log(
      'Initiating Razorpay checkout: itemsCount=${cart.length}, subtotal=₹${cartNotifier.subtotal}, discount=₹$discount, shipping=₹${cartNotifier.shippingFee}, tax=₹${cartNotifier.taxAmount}, giftWrap=₹$giftWrapCharge => totalAmount=₹$totalAmount',
      name: 'Razorpay',
    );

    setState(() {
      _isPlacingOrder = true;
      _paymentProcessingStep = 'INITIALIZING SECURE GATEWAY...';
    });

    try {
      final amtInPaise = (totalAmount * 100).round();
      final currency = ref.read(currencyProvider).code;

      dev.log(
        'Requesting Razorpay order creation from backend: amount=₹$totalAmount ($amtInPaise paise), currency=$currency, couponCode=${appliedCoupon?.code}, giftWrap=$isGiftWrapped',
        name: 'Razorpay',
      );
      final orderData = await ref
          .read(paymentRepositoryProvider)
          .createRazorpayOrder(
            amount: totalAmount,
            cartItems: cart,
            couponCode: appliedCoupon?.code,
            discountAmount: discount,
            giftWrap: isGiftWrapped,
          );

      final razorpayOrderId = orderData['razorpayOrderId'] as String?;
      final amount = orderData['amount'] as int? ?? amtInPaise;
      final keyId = (orderData['keyId']?.toString() ?? '').trim();

      dev.log(
        'Backend order creation response: razorpayOrderId=$razorpayOrderId, keyId=$keyId, amount=$amount paise',
        name: 'Razorpay',
      );

      final bool hasKey =
          keyId.isNotEmpty &&
          !keyId.startsWith('YOUR_') &&
          keyId != 'your-razorpay-key-id';

      if (hasKey) {
        final profileUser = ref.read(profileNotifierProvider);
        final userPhone = profileUser?['phone']?.toString();
        final userEmail = profileUser?['email']?.toString();
        final contact = _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : (userPhone?.isNotEmpty == true ? userPhone! : '9876543210');
        final email = (userEmail != null && userEmail.trim().isNotEmpty)
            ? userEmail.trim()
            : 'customer@example.com';

        final options = <String, dynamic>{
          'key': keyId,
          'amount': amount,
          'name': 'FCI Seller',
          'description': '${cart.length} item(s) purchase',
          'retry': {'enabled': true, 'max_count': 2},
          'send_sms_hash': true,
          if (razorpayOrderId != null && razorpayOrderId.isNotEmpty)
            'order_id': razorpayOrderId,
          'currency': 'INR',
          'prefill': {'contact': contact, 'email': email},
          'theme': {'color': '#0d9488'},
          'modal': {
            'confirm_close': true,
            'handleback': true,
            'backdropclose': true,
          },
          'external': {
            'wallets': ['paytm', 'mobikwik'],
          },
        };
        try {
          dev.log(
            'Opening Razorpay SDK with options: $options',
            name: 'Razorpay',
          );
          _startRazorpayTimeout();
          _razorpay.open(options);
        } catch (sdkErr, stackTrace) {
          _cancelRazorpayTimeout();
          dev.log(
            'Error launching Razorpay SDK window: $sdkErr',
            name: 'Razorpay',
            error: sdkErr,
            stackTrace: stackTrace,
          );
          debugPrint('Razorpay SDK opening error: $sdkErr');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to launch Razorpay: $sdkErr'),
                backgroundColor: AppTheme.errorColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
            setState(() => _isPlacingOrder = false);
          }
        }
      } else {
        dev.log(
          'Razorpay Key ID missing or invalid ($keyId)',
          name: 'Razorpay',
        );
        throw Exception('Razorpay Key ID is not configured on server.');
      }
    } catch (e, stackTrace) {
      dev.log(
        'Razorpay payment initialization failed: $e',
        name: 'Razorpay',
        error: e,
        stackTrace: stackTrace,
      );
      _cancelRazorpayTimeout();
      if (mounted) {
        setState(() => _isPlacingOrder = false);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not start payment: ${e.toString().replaceAll('Exception: ', '')}. Please try again.',
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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

      final isGiftWrapped = ref.read(isGiftWrappedProvider);
      final order = await ref
          .read(orderProvider.notifier)
          .placeOrder(
            items: cart,
            subtotal: cartNotifier.subtotal,
            shippingFee: cartNotifier.shippingFee,
            taxAmount: cartNotifier.taxAmount,
            totalAmount: _calculateFinalTotalPayable(),
            address: address,
            addressId: (int.tryParse(_selectedAddressId ?? '') != null)
                ? _selectedAddressId
                : null,
            paymentMethod: _selectedPayment,
            giftWrap: isGiftWrapped,
          );

      cartNotifier.clearCart();

      ref
          .read(notificationProvider.notifier)
          .addNotification(
            title: 'Order Placed Successfully 🎉',
            body:
                'Your order #${order.id} has been confirmed. Tap to track progress.',
            type: 'order',
          );

      if (mounted) {
        setState(() => _paymentProcessingStep = 'ORDER PLACED SUCCESSFULLY ✨');
      }
      await Future.delayed(const Duration(milliseconds: 1000));
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

  // ── Helpers ─────────────────────────────────────────────────────────────
  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  Widget _sectionHeader(
    BuildContext context,
    ResponsiveText responsive,
    IconData icon,
    String title, {
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: colorScheme.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
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
      style: TextStyle(
        fontSize: responsive.fontSize14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: responsive.fontSize13,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        prefixIcon: Icon(
          icon,
          size: responsive.iconSize(18),
          color: AppTheme.primaryColor.withValues(alpha: 0.8),
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
    String? badgeText,
  }) {
    final isSelected = _selectedPayment == name;
    final themeColor = color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPayment = name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? themeColor.withValues(alpha: 0.07)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? themeColor
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: themeColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? themeColor.withValues(alpha: 0.15)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected
                    ? themeColor
                    : colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: responsive.fontSize14,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? themeColor
                              : colorScheme.onSurface,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.shade700,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: responsive.fontSize10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize11,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? themeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? themeColor
                      : colorScheme.outline.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(
    ResponsiveText responsive,
    ColorScheme colorScheme,
    String label,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
    bool isInfo = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize14 : responsive.fontSize13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            color: isInfo
                ? Colors.grey.shade500
                : (isTotal
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.65)),
            fontStyle: isInfo ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? responsive.fontSize16 : responsive.fontSize13,
            fontWeight: isTotal
                ? FontWeight.w900
                : (isInfo ? FontWeight.w400 : FontWeight.w700),
            color: isTotal
                ? AppTheme.primaryColor
                : (isDiscount
                      ? const Color(0xFF059669)
                      : (isInfo
                            ? Colors.grey.shade500
                            : colorScheme.onSurface)),
            fontStyle: isInfo ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }

  // ── Build Checkout Stepper Header ──
  Widget _buildCheckoutStepper(
    ResponsiveText responsive,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepperStep(responsive, '1', 'Cart', isCompleted: true),
          _stepperLine(colorScheme, isCompleted: true),
          _stepperStep(responsive, '2', 'Address', isActive: true),
          _stepperLine(colorScheme, isCompleted: false),
          _stepperStep(responsive, '3', 'Payment', isNext: true),
        ],
      ),
    );
  }

  Widget _stepperStep(
    ResponsiveText responsive,
    String number,
    String label, {
    bool isCompleted = false,
    bool isActive = false,
    bool isNext = false,
  }) {
    final color = isCompleted || isActive
        ? AppTheme.primaryColor
        : Colors.grey.shade400;
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.primaryColor
                : (isActive
                      ? AppTheme.primaryColor.withValues(alpha: 0.15)
                      : Colors.grey.shade200),
            border: Border.all(color: color, width: isActive ? 2 : 1),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    number,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize11,
            fontWeight: isActive || isCompleted
                ? FontWeight.w800
                : FontWeight.w500,
            color: isActive || isCompleted
                ? AppTheme.primaryColor
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _stepperLine(ColorScheme colorScheme, {required bool isCompleted}) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isCompleted
          ? AppTheme.primaryColor
          : colorScheme.outline.withValues(alpha: 0.2),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final currency = ref.watch(currencyProvider);
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

    final double giftWrapCharge = (isGiftWrapped && giftWrapConfig.enabled)
        ? giftWrappingCost
        : 0.0;
    final appliedCoupon = ref.watch(appliedCouponProvider);
    final couponDiscount = ref
        .read(appliedCouponProvider.notifier)
        .calculateDiscount(cartNotifier.subtotal);
    final totalPayable =
        (cartNotifier.subtotal -
                couponDiscount +
                cartNotifier.shippingFee +
                cartNotifier.exclusiveTaxAmount +
                giftWrapCharge)
            .clamp(0.0, double.infinity);
    final countriesAsync = ref.watch(apiCountriesProvider);
    final apiList = countriesAsync.value
        ?.map((c) => c['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final countriesList = (apiList != null && apiList.isNotEmpty)
        ? apiList
        : _kDefaultCountries;

    final apiIsoMap = <String, String>{};
    if (countriesAsync.value != null) {
      for (final c in countriesAsync.value!) {
        final code = c['code']?.toString().toUpperCase();
        final name = c['name']?.toString();
        if (code != null &&
            code.isNotEmpty &&
            name != null &&
            name.isNotEmpty) {
          apiIsoMap[code] = name;
        }
      }
    }
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('CHECKOUT')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Your cart is empty',
                style: TextStyle(
                  fontSize: responsive.fontSize16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'EXPLORE CATALOG',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'CHECKOUT',
              style: TextStyle(
                fontSize: responsive.fontSize16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back, size: responsive.iconSize(20)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/cart');
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Stepper bar
          _buildCheckoutStepper(responsive, colorScheme, isDark),

          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(
                    responsive.spacing(16),
                  ).copyWith(bottom: 120),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── EXPRESS DELIVERY BANNER ──
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryColor.withValues(alpha: 0.12),
                                Colors.teal.shade50.withValues(
                                  alpha: isDark ? 0.1 : 0.8,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guaranteed Express Delivery',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize13,
                                        fontWeight: FontWeight.w800,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Dispatched within 24 hours with live GPS tracking.',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize11,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── SHIPPING ADDRESS ──
                        _sectionHeader(
                          context,
                          responsive,
                          Icons.location_on_rounded,
                          'SHIPPING ADDRESS',
                        ),
                        _sectionCard(
                          context,
                          isDark,
                          colorScheme,
                          children: [
                            _buildSavedAddressSelector(
                              context,
                              responsive,
                              colorScheme,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    responsive,
                                    _firstNameController,
                                    'First Name',
                                    Icons.person_outline_rounded,
                                    validator: _required,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    responsive,
                                    _lastNameController,
                                    'Last Name',
                                    Icons.person_outline_rounded,
                                    validator: _required,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              responsive,
                              _addressController,
                              'Street Address & House No.',
                              Icons.home_work_outlined,
                              validator: _required,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    responsive,
                                    _cityController,
                                    'City / District',
                                    Icons.location_city_rounded,
                                    validator: _required,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildField(
                                    responsive,
                                    _zipController,
                                    'Pincode / ZIP',
                                    Icons.pin_drop_rounded,
                                    keyboardType: TextInputType.number,
                                    validator: _required,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _matchCountryName(
                                _selectedCountry,
                                countriesList,
                                isoMap: apiIsoMap,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Country',
                                labelStyle: TextStyle(
                                  fontSize: responsive.fontSize13,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.public_rounded,
                                  size: responsive.iconSize(18),
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              items: countriesList
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize14,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setState(
                                () => _selectedCountry = val ?? 'India',
                              ),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please select a country'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              responsive,
                              _phoneController,
                              'Mobile Phone Number',
                              Icons.phone_android_rounded,
                              keyboardType: TextInputType.phone,
                              validator: _required,
                            ),
                          ],
                        ),

                        if (giftWrapConfig.enabled) ...[
                          const SizedBox(height: 20),
                          _sectionHeader(
                            context,
                            responsive,
                            Icons.card_giftcard_rounded,
                            'GIFT WRAPPING',
                          ),
                          _sectionCard(
                            context,
                            isDark,
                            colorScheme,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.card_giftcard_rounded,
                                      color: Colors.amber,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LUXURY GIFT WRAPPING',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Includes luxury box & satin ribbon (${currency.formatPrice(giftWrapConfig.charge)})',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize10,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isGiftWrapped,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(isGiftWrappedProvider.notifier)
                                          .toggle(val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 20),

                        // ── PAYMENT METHOD ──
                        _sectionHeader(
                          context,
                          responsive,
                          Icons.account_balance_wallet_rounded,
                          'SELECT PAYMENT METHOD',
                        ),
                        _sectionCard(
                          context,
                          isDark,
                          colorScheme,
                          children: [
                            _buildPaymentOption(
                              context,
                              responsive,
                              colorScheme,
                              'Razorpay',
                              Icons.bolt_rounded,
                              subtitle:
                                  'Instant UPI (Google Pay, PhonePe), Cards & NetBanking',
                              color: const Color(0xFF0D9488),
                              badgeText: 'FASTEST',
                            ),
                            const SizedBox(height: 12),
                            _buildPaymentOption(
                              context,
                              responsive,
                              colorScheme,
                              'Cash on Delivery',
                              Icons.payments_rounded,
                              subtitle:
                                  'Pay via Cash / UPI upon order delivery at door',
                              color: const Color(0xFF047857),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── ORDER SUMMARY PREVIEW ──
                        _sectionHeader(
                          context,
                          responsive,
                          Icons.receipt_long_rounded,
                          'ORDER SUMMARY',
                          trailing: GestureDetector(
                            onTap: () => setState(
                              () => _showItemSummary = !_showItemSummary,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${cart.length} item(s)',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _showItemSummary
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        _sectionCard(
                          context,
                          isDark,
                          colorScheme,
                          children: [
                            // Mini horizontal item gallery preview
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: cart.length,
                                itemBuilder: (context, idx) {
                                  final item = cart[idx];
                                  return Container(
                                    margin: const EdgeInsets.only(right: 10),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: CachedNetworkImage(
                                            imageUrl: item.displayImageUrl,
                                            width: 54,
                                            height: 54,
                                            fit: BoxFit.cover,
                                            memCacheWidth: 200,
                                            placeholder: (_, __) => Container(
                                              color: Colors.grey.shade200,
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(
                                                    Icons.image,
                                                    size: 20,
                                                  ),
                                                ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'x${item.quantity}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),

                            if (_showItemSummary) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 10),
                              ...cart.map((item) {
                                final itemTotal =
                                    item.product.price * item.quantity;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.product.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.quantity} × ${currency.formatPrice(item.product.price)}',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize11,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                              }),
                            ],

                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),

                            _priceRow(
                              responsive,
                              colorScheme,
                              'Subtotal',
                              currency.formatPrice(cartNotifier.subtotal),
                            ),
                            if (couponDiscount > 0) ...[
                              const SizedBox(height: 10),
                              _priceRow(
                                responsive,
                                colorScheme,
                                'Coupon Discount (${appliedCoupon?.code})',
                                '-${currency.formatPrice(couponDiscount)}',
                                isDiscount: true,
                              ),
                            ],
                            const SizedBox(height: 10),
                            _priceRow(
                              responsive,
                              colorScheme,
                              'Delivery Charge',
                              currency.formatPrice(cartNotifier.shippingFee),
                            ),
                            const SizedBox(height: 10),
                            if (cartNotifier.taxBreakdown.length > 1) ...[
                              for (final item in cartNotifier.taxBreakdown) ...[
                                const SizedBox(height: 6),
                                _priceRow(
                                  responsive,
                                  colorScheme,
                                  item['name'] as String,
                                  currency.formatPrice(
                                    item['taxAmount'] as double,
                                  ),
                                ),
                              ],
                            ] else if (cartNotifier
                                .taxBreakdown
                                .isNotEmpty) ...[
                              _priceRow(
                                responsive,
                                colorScheme,
                                cartNotifier.taxBreakdown.first['name'] as String,
                                currency.formatPrice(
                                  cartNotifier.taxBreakdown.first['taxAmount']
                                      as double,
                                ),
                              ),
                            ] else if (cartNotifier.taxAmount > 0) ...[
                              _priceRow(
                                responsive,
                                colorScheme,
                                'Taxes',
                                currency.formatPrice(cartNotifier.taxAmount),
                              ),
                            ] else ...[
                              _priceRow(
                                responsive,
                                colorScheme,
                                'Taxes',
                                currency.formatPrice(cartNotifier.taxAmount),
                              ),
                            ],
                            if (isGiftWrapped && giftWrapConfig.enabled) ...[
                              const SizedBox(height: 10),
                              _priceRow(
                                responsive,
                                colorScheme,
                                'Gift Wrapping',
                                currency.formatPrice(giftWrapCharge),
                              ),
                            ],
                            const Divider(height: 24),
                            _priceRow(
                              responsive,
                              colorScheme,
                              'Total Amount',
                              currency.formatPrice(totalPayable),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── STICKY BOTTOM ACTION BAR ──
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      MediaQuery.of(context).padding.bottom + 14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.08,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
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
                              Text(
                                'TOTAL PAYABLE',
                                style: TextStyle(
                                  fontSize: responsive.fontSize10,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currency.formatPrice(totalPayable),
                                style: TextStyle(
                                  fontSize: responsive.fontSize20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: GestureDetector(
                            onTap: _isPlacingOrder ? null : _handlePlaceOrder,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: _isPlacingOrder
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          Color(0xFF0D9488),
                                          Color(0xFF14B8A6),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                color: _isPlacingOrder
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.5,
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isPlacingOrder
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: _isPlacingOrder
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              _paymentProcessingStep ??
                                                  'Processing...',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () {
                                              _cancelRazorpayTimeout();
                                              setState(() {
                                                _isPlacingOrder = false;
                                                _paymentProcessingStep = null;
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'CANCEL ✕',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _selectedPayment == 'Razorpay'
                                                ? Icons.lock_rounded
                                                : Icons.check_circle_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedPayment == 'Razorpay'
                                                ? 'PAY NOW'
                                                : 'PLACE ORDER',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressSelector(
    BuildContext context,
    ResponsiveText responsive,
    ColorScheme colorScheme,
  ) {
    final savedAddresses = ref.watch(addressNotifierProvider);
    if (savedAddresses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.touch_app_rounded,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 6),
            const Text(
              '1-TAP AUTOFILL SAVED ADDRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 54,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: savedAddresses.length,
            itemBuilder: (context, index) {
              final addr = savedAddresses[index];
              final typeStr = addr.type.toLowerCase();
              final isHome = typeStr == 'home';
              final isCurrent = typeStr == 'current';
              final isWork = typeStr == 'work' || typeStr == 'office';

              final labelText = isHome
                  ? 'HOME'
                  : (isCurrent ? 'CURRENT' : (isWork ? 'OFFICE' : 'OTHER'));

              final typeIcon = isHome
                  ? Icons.home_rounded
                  : (isCurrent
                        ? Icons.my_location_rounded
                        : (isWork
                              ? Icons.business_rounded
                              : Icons.label_rounded));

              return Container(
                margin: const EdgeInsets.only(right: 10),
                child: ActionChip(
                  avatar: Icon(
                    typeIcon,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  label: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            labelText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (addr.isDefault) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '(Default)',
                              style: TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${addr.fullName.isNotEmpty ? addr.fullName : 'Saved Address'} — ${addr.city}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  backgroundColor: colorScheme.surface,
                  side: BorderSide(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final parts = addr.fullName.trim().split(' ');
                    setState(() {
                      _selectedAddressId = addr.id;
                      _firstNameController.text = parts.first;
                      _lastNameController.text = parts.length > 1
                          ? parts.sublist(1).join(' ')
                          : '';
                      _addressController.text =
                          addr.addressLine1 +
                          (addr.addressLine2.isNotEmpty
                              ? ', ${addr.addressLine2}'
                              : '');
                      _cityController.text = addr.city;
                      _zipController.text = addr.pincode;
                      _phoneController.text = addr.phone;
                      if (addr.country.isNotEmpty) {
                        final countriesData = ref
                            .read(apiCountriesProvider)
                            .value;
                        final apiList = countriesData
                            ?.map((c) => c['name']?.toString() ?? '')
                            .where((name) => name.isNotEmpty)
                            .toList();
                        final countriesList =
                            (apiList != null && apiList.isNotEmpty)
                            ? apiList
                            : _kDefaultCountries;
                        final apiIsoMap = <String, String>{};
                        if (countriesData != null) {
                          for (final c in countriesData) {
                            final code = c['code']?.toString().toUpperCase();
                            final name = c['name']?.toString();
                            if (code != null &&
                                code.isNotEmpty &&
                                name != null &&
                                name.isNotEmpty) {
                              apiIsoMap[code] = name;
                            }
                          }
                        }
                        _selectedCountry = _matchCountryName(
                          addr.country,
                          countriesList,
                          isoMap: apiIsoMap,
                        );
                      }
                    });
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Auto-filled ${isHome ? 'Home' : (isWork ? 'Office' : 'Saved')} Address!',
                        ),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
