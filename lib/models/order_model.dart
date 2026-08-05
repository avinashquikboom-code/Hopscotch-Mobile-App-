import 'package:hopscotch/models/cart_item_model.dart';

class OrderModel {
  final String id;
  final List<CartItemModel> items;
  final double totalAmount;
  final String orderDate;
  final String status; // Pending, Processing, Shipped, Delivered, Cancelled
  final String shippingAddress;
  final String paymentMethod;
  final String? trackingNumber;
  final double taxAmount;
  final double subtotal;
  final double shippingFee;
  final bool giftWrapped;
  final double giftWrapCharge;
  final String sellerName;
  final String sellerContact;
  final String sellerAddress;

  const OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    this.taxAmount = 0.0,
    this.subtotal = 0.0,
    this.shippingFee = 0.0,
    this.giftWrapped = false,
    this.giftWrapCharge = 0.0,
    this.sellerName = 'FCI Seller Retail Pvt. Ltd.',
    this.sellerContact = '+91 9876543210',
    this.sellerAddress = '',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final parsedItems = CartItemModel.listFromJson(json['items'] ?? json['orderItems']);
    final itemsSubtotal = parsedItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );

    final rawSubtotal = _asDouble(json['subtotal'] ?? json['subTotal'] ?? json['sub_total']);
    final subtotal = rawSubtotal > 0 ? rawSubtotal : itemsSubtotal;

    final rawTax = _asDouble(json['taxAmount'] ?? json['totalTax'] ?? json['tax_amount'] ?? json['tax']);
    final rawShipping = _asDouble(json['shippingFee'] ?? json['shipping_fee'] ?? json['shippingAmount'] ?? json['shipping_amount'] ?? json['shipping']);
    final isGiftWrapped = json['giftWrapped'] == true || json['gift_wrapped'] == true;
    final giftWrapCharge = _asDouble(json['giftWrapCharge'] ?? json['gift_wrap_charge']);

    final sellerName = (json['sellerNameSnapshot'] ?? json['sellerName'] ?? json['seller_name'] ?? 'FCI Seller Retail Pvt. Ltd.').toString();
    final sellerContact = (json['sellerContactSnapshot'] ?? json['sellerContact'] ?? json['seller_contact'] ?? json['sellerContactNumber'] ?? '+91 9876543210').toString();
    final sellerAddress = (json['sellerAddressSnapshot'] ?? json['sellerAddress'] ?? json['seller_address'] ?? '').toString();

    final parsedTotal = json['totalAmount'] is num
        ? (json['totalAmount'] as num).toDouble()
        : double.tryParse('${json['totalAmount'] ?? json['total']}');
    final totalAmount = parsedTotal ?? (subtotal + rawShipping + rawTax + giftWrapCharge);

    final shippingFee = (rawShipping == 0 && totalAmount > (subtotal + rawTax + giftWrapCharge))
        ? (totalAmount - subtotal - rawTax - giftWrapCharge)
        : rawShipping;

    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      items: parsedItems,
      totalAmount: totalAmount,
      orderDate: (json['orderDate'] ?? json['createdAt'] ?? json['created_at'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      shippingAddress: _parseAddress(json['shippingAddress'] ?? json['address']),
      paymentMethod: (json['paymentMethod'] ?? json['payment_method'] ?? '').toString(),
      trackingNumber: json['trackingNumber'] as String? ?? json['tracking_number'] as String?,
      taxAmount: rawTax,
      subtotal: subtotal,
      shippingFee: shippingFee,
      giftWrapped: isGiftWrapped,
      giftWrapCharge: giftWrapCharge,
      sellerName: sellerName,
      sellerContact: sellerContact,
      sellerAddress: sellerAddress,
    );
  }

  static double _asDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      'status': status,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'taxAmount': taxAmount,
      'subtotal': subtotal,
      'shippingFee': shippingFee,
    };
  }

  static String _parseAddress(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final name = raw['name'] ?? raw['fullName'] ?? raw['recipientName'] ?? '';
      final phone = raw['phone'] ??
          raw['phoneNumber'] ??
          raw['mobile'] ??
          raw['mobileNo'] ??
          raw['mobile_number'] ??
          raw['contactPhone'] ??
          raw['contactNumber'] ??
          raw['phone_no'] ??
          '';
      final line1 = raw['line1'] ?? raw['addressLine1'] ?? raw['street'] ?? raw['address'] ?? '';
      final line2 = raw['line2'] ?? raw['addressLine2'] ?? '';
      final city = raw['city'] ?? '';
      final state = raw['state'] ?? '';
      final pincode = raw['pincode'] ?? raw['postalCode'] ?? raw['zip'] ?? raw['zipCode'] ?? '';
      final country = raw['country'] ?? '';

      final lines = <String>[];
      if (name.toString().trim().isNotEmpty) lines.add(name.toString().trim());
      final cleanPhone = phone.toString().trim();
      if (cleanPhone.isNotEmpty && cleanPhone != '0000000000' && cleanPhone != '00000') {
        lines.add('Phone: $cleanPhone');
      }
      final streetParts = [line1, line2].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
      if (streetParts.isNotEmpty) lines.add(streetParts);
      final cityParts = [city, state, pincode, country].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');
      if (cityParts.isNotEmpty) lines.add(cityParts);

      return lines.join('\n');
    }
    return raw.toString();
  }

  static List<OrderModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(OrderModel.fromJson)
          .toList();
    }
    return [];
  }

  OrderModel copyWith({
    String? id,
    List<CartItemModel>? items,
    double? totalAmount,
    String? orderDate,
    String? status,
    String? shippingAddress,
    String? paymentMethod,
    String? trackingNumber,
  }) {
    return OrderModel(
      id: id ?? this.id,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      trackingNumber: trackingNumber ?? this.trackingNumber,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is OrderModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
