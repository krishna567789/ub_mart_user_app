import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'cart_provider.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<OrderModel> _userOrders = [];
  OrderModel? _currentPlacingOrder;
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get userOrders => _userOrders;
  OrderModel? get currentPlacingOrder => _currentPlacingOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserOrders({required String storeId, required String phone}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.get(
        '/orders',
        storeId: storeId,
        queryParams: {'phone': phone},
      );
      if (res is List) {
        _userOrders = res.map((o) => OrderModel.fromJson(o)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder({required String orderId, required String storeId}) async {
    try {
      final res = await _apiService.patch(
        '/orders/$orderId',
        body: {'status': 'CANCELLED'},
        storeId: storeId,
      );
      if (res != null) {
        final index = _userOrders.indexWhere((o) => o.id == orderId || o.orderId == orderId);
        if (index != -1) {
          final updated = OrderModel.fromJson(res);
          _userOrders[index] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      notifyListeners();
      return false;
    }
  }

  Future<OrderModel?> placeOrder({
    required String storeId,
    required UserModel user,
    required AddressModel deliveryAddress,
    required CartProvider cart,
    required String paymentMethod, // COD, ONLINE, WALLET
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String humanReadableOrderId = "UB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

      final Map<String, dynamic> body = {
        'orderId': humanReadableOrderId,
        'user': user.id,
        'customerName': user.name,
        'customerPhone': user.phone,
        'deliveryAddress': deliveryAddress.toJson(),
        'items': cart.itemList.map((i) => {
          'product': i.product.id,
          'name': i.product.name,
          'variantSize': i.selectedVariant.size,
          'quantity': i.quantity,
          'priceAtPurchase': i.selectedVariant.price,
          'imageUrl': i.product.images.isNotEmpty ? i.product.images.first : '',
        }).toList(),
        'itemTotal': cart.itemTotal,
        'deliveryFee': cart.deliveryFee,
        'taxAmount': 0.0,
        'discountAmount': cart.discountAmount,
        'totalAmount': cart.grandTotal,
        'status': 'PENDING',
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentMethod == 'COD' ? 'PENDING' : 'PAID',
      };

      final res = await _apiService.post('/orders', body: body, storeId: storeId);
      final OrderModel newOrder = OrderModel.fromJson(res);
      _currentPlacingOrder = newOrder;
      _userOrders.insert(0, newOrder);

      cart.clearCart();
      _isLoading = false;
      notifyListeners();
      return newOrder;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
