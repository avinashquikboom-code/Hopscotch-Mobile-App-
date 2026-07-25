class CouponModel {
  final String id;
  final String title;
  final String description;
  final String code;
  final int discount;
  final String type;
  final double minOrder;
  final double maxDiscount;
  final DateTime expiry;
  final String category;
  final bool isExclusive;
  final bool isApplied;

  CouponModel({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
    required this.discount,
    required this.type,
    required this.minOrder,
    required this.maxDiscount,
    required this.expiry,
    required this.category,
    this.isExclusive = false,
    this.isApplied = false,
  });

  CouponModel copyWith({bool? isApplied}) {
    return CouponModel(
      id: id,
      title: title,
      description: description,
      code: code,
      discount: discount,
      type: type,
      minOrder: minOrder,
      maxDiscount: maxDiscount,
      expiry: expiry,
      category: category,
      isExclusive: isExclusive,
      isApplied: isApplied ?? this.isApplied,
    );
  }
}
