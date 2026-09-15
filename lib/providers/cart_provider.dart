import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/coupon_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

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
  // Use global apiService instead of a local instance
  // final ApiService _apiService = ApiService();
  String? _userId;

  final Map<String, CartItem> _items = {}; // key: productId_variantSize
  CouponModel? _appliedCoupon;
  double _validatedDiscount = 0.0;
  List<CouponModel> _availableCoupons = [];
  bool _isLoadingCoupons = false;

  Map<String, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  CouponModel? get appliedCoupon => _appliedCoupon;
  String? get couponCode => _appliedCoupon?.code;
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
    if (_validatedDiscount > 0) return _validatedDiscount;
    return _appliedCoupon!.calculateDiscount(itemTotal);
  }

  double _deliveryTip = 0.0;
  double get deliveryTip => _deliveryTip;
  void setDeliveryTip(double tip) {
    _deliveryTip = tip;
    notifyListeners();
  }

  final Set<String> _deliveryInstructions = {};
  Set<String> get deliveryInstructions => _deliveryInstructions;
  void toggleDeliveryInstruction(String instruction) {
    if (_deliveryInstructions.contains(instruction)) {
      _deliveryInstructions.remove(instruction);
    } else {
      _deliveryInstructions.add(instruction);
    }
    notifyListeners();
  }

  double get grandTotal {
    final total = itemTotal + deliveryFee + deliveryTip - discountAmount;
    return total < 0 ? 0.0 : total;
  }

  double get totalMrp {
    return _items.values.fold(0.0, (sum, item) {
      final mrp = item.selectedVariant.originalPrice ?? item.selectedVariant.price;
      return sum + (mrp * item.quantity);
    });
  }

  double get totalSavings {
    final productSavings = totalMrp - itemTotal;
    final total = (productSavings > 0 ? productSavings : 0.0) + discountAmount;
    return total;
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
    syncCartOnline();
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
    syncCartOnline();
  }

  void deleteItemCompletely(String productId, String variantSize) {
    final key = "${productId}_$variantSize";
    _items.remove(key);
    notifyListeners();
    syncCartOnline();
  }

  void clearCart() {
    _items.clear();
    _appliedCoupon = null;
    _validatedDiscount = 0.0;
    _deliveryTip = 0.0;
    _deliveryInstructions.clear();
    notifyListeners();
    syncCartOnline();
  }

  Future<void> fetchCoupons(String storeId) async {
    _isLoadingCoupons = true;
    notifyListeners();

    try {
      final res = await apiService.get('/coupons', storeId: storeId);
      if (res is List) {
        _availableCoupons = res
            .map((c) => CouponModel.fromJson(c))
            .where((c) => c.isActive)
            .toList();
      }
    } catch (_) {
    } finally {
      _isLoadingCoupons = false;
      notifyListeners();
    }
  }

  // Validate coupon directly against backend API
  Future<Map<String, dynamic>> validateAndApplyCouponOnline({
    required String code,
    required String storeId,
  }) async {
    try {
      final res = await apiService.post(
        '/coupons',
        body: {
          'action': 'VALIDATE',
          'code': code.trim().toUpperCase(),
          'cartTotal': itemTotal,
          'storeId': storeId,
        },
        storeId: storeId,
      );

      if (res != null && res['valid'] == true) {
        _appliedCoupon = CouponModel.fromJson(res['coupon']);
        _validatedDiscount = (res['discountAmount'] as num?)?.toDouble() ?? 0.0;
        notifyListeners();
        return {
          'success': true,
          'message': res['message'] ?? 'Coupon applied!',
        };
      } else {
        return {
          'success': false,
          'message': res?['message'] ?? 'Invalid coupon',
        };
      }
    } catch (e) {
      // Fallback local check
      final success = applyCoupon(code);
      return {
        'success': success,
        'message': success
            ? 'Coupon applied!'
            : 'Invalid coupon or order total too low',
      };
    }
  }

  bool applyCoupon(dynamic coupon) {
    if (coupon is String) {
      try {
        final found = _availableCoupons.firstWhere(
          (c) => c.code.toUpperCase() == coupon.trim().toUpperCase(),
        );
        return applyCoupon(found);
      } catch (_) {
        return false;
      }
    }
    if (coupon is CouponModel) {
      if (itemTotal >= coupon.minOrderValue) {
        _appliedCoupon = coupon;
        _validatedDiscount = coupon.calculateDiscount(itemTotal);
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _validatedDiscount = 0.0;
    notifyListeners();
  }

  Future<void> loadCartFromBackend() async {
    final user = await StorageService.getUser();
    if (user == null) return;
    _userId = user.id;
    try {
      final res = await apiService.get('/users/$_userId/cart');
      if (res != null && res['success'] == true) {
        final List cartItems = res['cart'] ?? [];
        _items.clear();
        for (var item in cartItems) {
          if (item['productId'] != null && item['productId'] is Map) {
            final product = ProductModel.fromJson(item['productId']);
            final String variantSize = item['variantSize'];
            final int quantity = item['quantity'] ?? 1;
            
            final variant = product.variants.firstWhere(
              (v) => v.size == variantSize,
              orElse: () => product.variants.first,
            );
            
            final key = "${product.id}_$variantSize";
            _items[key] = CartItem(
              product: product,
              selectedVariant: variant,
              quantity: quantity,
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  Future<void> syncCartOnline() async {
    if (_userId == null) {
      final user = await StorageService.getUser();
      if (user != null) _userId = user.id;
    }
    if (_userId == null) return;

    final cartList = _items.values.map((item) => {
      'productId': item.product.id,
      'variantSize': item.selectedVariant.size,
      'quantity': item.quantity,
    }).toList();

    try {
      await apiService.put('/users/$_userId/cart', body: { 'cart': cartList });
    } catch (e) {
      debugPrint('Error syncing cart: $e');
    }
  }
}
