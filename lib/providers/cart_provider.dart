import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/coupon_model.dart';
import '../services/api_service.dart';

class CartItem {
  final ProductModel product;
  final ProductVariantModel selectedVariant;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedVariant,
    this.quantity = 1,
  });

  double get totalPrice => selectedVariant.price * quantity;
}

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final Map<String, CartItem> _items = {}; // key: productId_variantSize
  CouponModel? _appliedCoupon;
  List<CouponModel> _availableCoupons = [];
  bool _isLoadingCoupons = false;

  Map<String, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  CouponModel? get appliedCoupon => _appliedCoupon;
  List<CouponModel> get availableCoupons => _availableCoupons;
  bool get isLoadingCoupons => _isLoadingCoupons;

  double get itemTotal {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get deliveryFee {
    if (itemTotal == 0) return 0.0;
    return itemTotal > 500 ? 0.0 : 30.0; // Free delivery over ₹500
  }

  double get discountAmount {
    if (_appliedCoupon == null || itemTotal == 0) return 0.0;
    return _appliedCoupon!.calculateDiscount(itemTotal);
  }

  double get grandTotal {
    final total = itemTotal + deliveryFee - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  int getQuantity(String productId, String variantSize) {
    final key = "${productId}_$variantSize";
    return _items[key]?.quantity ?? 0;
  }

  void addItem(ProductModel product, ProductVariantModel variant) {
    final key = "${product.id}_${variant.size}";
    if (_items.containsKey(key)) {
      _items[key]!.quantity += 1;
    } else {
      _items[key] = CartItem(
        product: product,
        selectedVariant: variant,
        quantity: 1,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId, String variantSize) {
    final key = "${productId}_$variantSize";
    if (!_items.containsKey(key)) return;

    if (_items[key]!.quantity > 1) {
      _items[key]!.quantity -= 1;
    } else {
      _items.remove(key);
    }
    notifyListeners();
  }

  void deleteItemCompletely(String productId, String variantSize) {
    final key = "${productId}_$variantSize";
    _items.remove(key);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  Future<void> fetchCoupons(String storeId) async {
    _isLoadingCoupons = true;
    notifyListeners();

    try {
      final res = await _apiService.get('/coupons', storeId: storeId);
      if (res is List) {
        _availableCoupons = res
            .map((c) => CouponModel.fromJson(c))
            .where((c) => c.isActive)
            .toList();
      }
    } catch (_) {} finally {
      _isLoadingCoupons = false;
      notifyListeners();
    }
  }

  bool applyCoupon(CouponModel coupon) {
    if (itemTotal >= coupon.minOrderValue) {
      _appliedCoupon = coupon;
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    notifyListeners();
  }
}
