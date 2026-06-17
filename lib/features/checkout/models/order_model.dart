import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hopscotch/features/cart_wishlist/models/cart_item_model.dart';

part 'order_model.freezed.dart';
part 'order_model.g.dart';

@freezed
class OrderModel with _$OrderModel {
  const factory OrderModel({
    required String id,
    required List<CartItemModel> items,
    required double totalAmount,
    required String orderDate,
    required String status, // Pending, Processing, Shipped, Delivered, Cancelled
    required String shippingAddress,
    required String paymentMethod,
    String? trackingNumber,
  }) = _OrderModel;

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
}
