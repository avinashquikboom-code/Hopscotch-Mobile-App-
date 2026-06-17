import 'package:freezed_annotation/freezed_annotation.dart';
import '../../product/models/product_model.dart';

part 'cart_item_model.freezed.dart';
part 'cart_item_model.g.dart';

@freezed
class CartItemModel with _$CartItemModel {
  const factory CartItemModel({
    required String id,
    required ProductModel product,
    required int quantity,
    String? selectedSize,
    String? selectedColor,
  }) = _CartItemModel;

  factory CartItemModel.fromJson(Map<String, dynamic> json) => _$CartItemModelFromJson(json);
}
