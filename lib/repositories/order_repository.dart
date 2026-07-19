import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hopscotch/api/api_service.dart';
import 'package:hopscotch/api/orders_api.dart';
import 'package:hopscotch/models/order_model.dart';
import 'package:hopscotch/providers/api_provider.dart';

// ── OrdersApi provider ──────────────────────────────────────────────────────
final ordersApiProvider = Provider<OrdersApi>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return OrdersApi(apiService);
});

// ── OrderNotifier — wraps the backend API ───────────────────────────────────
class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrdersApi _api;

  OrderNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  /// Fetch the authenticated user's orders from the backend.
  Future<void> fetchOrders({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.getOrders(limit: 50, status: status);
      final json = response.data;
      // Backend returns { orders: [...], pagination: {...} }
      final rawList = json['orders'] ?? json['data']?['orders'] ?? json['data'] ?? [];
      final orders = OrderModel.listFromJson(rawList);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Place a new order through the backend (requires an addressId).
  /// Automatically refreshes the order list afterwards.
  Future<OrderModel> placeOrder({required String addressId}) async {
    final response = await _api.createOrder(addressId: addressId);
    final rawOrder = response.data['data'] ?? response.data;
    final newOrder = OrderModel.fromJson(rawOrder is Map<String, dynamic>
        ? rawOrder
        : {'id': '', 'status': 'PENDING', 'totalAmount': 0});
    // Refresh order list so UI is in sync with backend
    await fetchOrders();
    return newOrder;
  }

  /// Cancel an order and refresh the list.
  Future<void> cancelOrder(String orderId) async {
    await _api.cancelOrder(orderId);
    await fetchOrders();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final orderProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  final api = ref.read(ordersApiProvider);
  return OrderNotifier(api);
});

// ── Convenience: a FutureProvider to get a single order by ID ────────────────
final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final api = ref.read(ordersApiProvider);
  final response = await api.getOrderById(orderId);
  final raw = response.data['data'] ?? response.data;
  if (raw == null) return null;
  return OrderModel.fromJson(raw as Map<String, dynamic>);
});
