class CouponModel {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double maxDiscountAmount;
  final double minOrderValue;
  final bool isFirstOrderOnly;
  final bool isActive;

  CouponModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscountAmount,
    required this.minOrderValue,
    required this.isFirstOrderOnly,
    required this.isActive,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      id: json['_id'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'FLAT',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      maxDiscountAmount: (json['maxDiscountAmount'] ?? 0).toDouble(),
      minOrderValue: (json['minOrderValue'] ?? 0).toDouble(),
      isFirstOrderOnly: json['isFirstOrderOnly'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  double calculateDiscount(double orderTotal) {
    if (orderTotal < minOrderValue) return 0;

    if (discountType == 'FLAT') {
      return discountValue > orderTotal ? orderTotal : discountValue;
    } else {
      double discount = (orderTotal * discountValue) / 100;
      if (maxDiscountAmount > 0 && discount > maxDiscountAmount) {
        discount = maxDiscountAmount;
      }
      return discount;
    }
  }
}
