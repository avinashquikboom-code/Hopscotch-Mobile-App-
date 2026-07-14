import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/models/cart_item_model.dart';
import 'package:hopscotch/models/order_model.dart';

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  OrderNotifier() : super([]);

  Future<OrderModel> placeOrder({
    required List<CartItemModel> items,
    required double totalAmount,
    required String address,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate checkout server latency

    final newOrder = OrderModel(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      items: items,
      totalAmount: totalAmount,
      orderDate: _formatDate(DateTime.now()),
      status: 'Processing',
      shippingAddress: address,
      paymentMethod: paymentMethod,
      trackingNumber: 'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}',
    );

    state = [newOrder, ...state];
    return newOrder;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});
