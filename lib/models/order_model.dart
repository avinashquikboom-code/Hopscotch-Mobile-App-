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
      shippingAddress: (json['shippingAddress'] ?? json['address'] ?? '').toString(),
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
