import 'package:hopscotch/models/product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;

  const CartItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedSize,
    this.selectedColor,
  });

  /// Calculates percentage discount for the product item
  double get discount => (product.discountPercentage / 100.0) * product.price;

  /// Returns complete product data map
  Map<String, dynamic> get productMeta => product.toJson();

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      product: ProductModel.fromJson(
        (json['product'] as Map<String, dynamic>?) ?? const {},
      ),
      quantity: json['quantity'] is num
          ? (json['quantity'] as num).toInt()
          : int.tryParse('${json['quantity']}') ?? 1,
      selectedSize: json['selectedSize'] as String? ?? json['size'] as String?,
      selectedColor: json['selectedColor'] as String? ?? json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
    };
  }

  static List<CartItemModel> listFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map<String, dynamic>>()
          .map(CartItemModel.fromJson)
          .toList();
    }
    return [];
  }

  CartItemModel copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) || (other is CartItemModel && other.id == id);
  }

  @override
  int get hashCode => id.hashCode;
}
