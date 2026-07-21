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

  const OrderModel({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      items: CartItemModel.listFromJson(json['items'] ?? json['orderItems']),
      totalAmount: json['totalAmount'] is num
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse('${json['totalAmount'] ?? json['total']}') ?? 0.0,
      orderDate: (json['orderDate'] ?? json['createdAt'] ?? json['created_at'] ?? '').toString(),
      status: (json['status'] ?? 'Pending').toString(),
      shippingAddress: _parseAddress(json['shippingAddress'] ?? json['address']),
      paymentMethod: (json['paymentMethod'] ?? json['payment_method'] ?? '').toString(),
      trackingNumber: json['trackingNumber'] as String? ?? json['tracking_number'] as String?,
    );
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
    };
  }

  static String _parseAddress(dynamic raw) {
    if (raw == null) return '';
    if (raw is String) return raw;
    if (raw is Map) {
      final name = raw['name'] ?? raw['fullName'] ?? raw['recipientName'] ?? '';
      final phone = raw['phone'] ?? raw['phoneNumber'] ?? raw['contactPhone'] ?? '';
      final line1 = raw['line1'] ?? raw['addressLine1'] ?? raw['street'] ?? raw['address'] ?? '';
      final line2 = raw['line2'] ?? raw['addressLine2'] ?? '';
      final city = raw['city'] ?? '';
      final state = raw['state'] ?? '';
      final pincode = raw['pincode'] ?? raw['postalCode'] ?? raw['zip'] ?? raw['zipCode'] ?? '';
      final country = raw['country'] ?? '';

      final lines = <String>[];
      if (name.toString().trim().isNotEmpty) lines.add(name.toString().trim());
      if (phone.toString().trim().isNotEmpty) lines.add('Phone: ${phone.toString().trim()}');
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
