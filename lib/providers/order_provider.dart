import 'dart:async';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/api_config.dart';
import 'cart_provider.dart';

class OrderProvider with ChangeNotifier {
  final ApiService _apiService = apiService;

  List<OrderModel> _userOrders = [];
  OrderModel? _currentPlacingOrder;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _liveTrackingTimer;
  String? _trackedOrderId;

  List<OrderModel> get userOrders => _userOrders;
  OrderModel? get currentPlacingOrder => _currentPlacingOrder;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get trackedOrderId => _trackedOrderId;

  OrderModel? get activeOrder {
    try {
      return _userOrders.firstWhere(
        (o) =>
            o.status != 'DELIVERED' &&
            o.status != 'CANCELLED' &&
            o.status != 'REJECTED',
      );
    } catch (_) {
      return null;
    }
  }

  List<OrderModel> get activeOrders {
    return _userOrders
        .where(
          (o) =>
              o.status != 'DELIVERED' &&
              o.status != 'CANCELLED' &&
              o.status != 'REJECTED',
        )
        .toList();
  }

  /// Start adaptive live tracking for an active order
  void startLiveTracking(String orderId, {String? storeId}) {
    if (_trackedOrderId == orderId && _liveTrackingTimer != null) return;

    stopLiveTracking();
    _trackedOrderId = orderId;

    // Fetch immediately
    fetchOrderDetails(orderId, storeId: storeId);

    // Poll every 10 seconds for real-time status and rider updates
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_trackedOrderId == null) return;
      final updated = await fetchOrderDetails(_trackedOrderId!, storeId: storeId);
      if (updated != null && (updated.status == 'DELIVERED' || updated.status == 'CANCELLED')) {
        stopLiveTracking();
      }
    });
  }

  /// Stop live tracking polling
  void stopLiveTracking() {
    _liveTrackingTimer?.cancel();
    _liveTrackingTimer = null;
    _trackedOrderId = null;
  }

  Future<OrderModel?> fetchOrderDetails(
    String orderId, {
    String? storeId,
  }) async {
    try {
      final res = await _apiService.get(
        '/orders/$orderId',
        storeId: storeId ?? ApiConfig.defaultStoreId,
      );
      if (res != null && res is Map<String, dynamic>) {
        final updated = OrderModel.fromJson(res);
        final index = _userOrders.indexWhere(
          (o) => o.id == updated.id || o.orderId == updated.orderId,
        );
        if (index != -1) {
          _userOrders[index] = updated;
        } else {
          _userOrders.insert(0, updated);
        }
        await StorageService.saveRecentOrders(_userOrders);
        notifyListeners();
        return updated;
      }
    } catch (e) {
      debugPrint("Error fetching order details: $e");
    }
    return null;
  }

  Future<void> fetchUserOrders({
    required String storeId,
    required String phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;

    // Load cached orders first so UI displays immediately
    if (_userOrders.isEmpty) {
      final cached = await StorageService.getRecentOrders();
      if (cached.isNotEmpty) {
        _userOrders = cached;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }

    try {
      final res = await _apiService.get(
        '/orders',
        storeId: storeId,
        queryParams: {'phone': phone},
      );
      if (res is List) {
        _userOrders = res.map((o) => OrderModel.fromJson(o)).toList();
        await StorageService.saveRecentOrders(_userOrders);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      // If network failed and list is empty, fallback to cached
      if (_userOrders.isEmpty) {
        final cached = await StorageService.getRecentOrders();
        if (cached.isNotEmpty) {
          _userOrders = cached;
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder({
    required String orderId,
    required String storeId,
  }) async {
    try {
      final res = await _apiService.patch(
        '/orders/$orderId',
        body: {'status': 'CANCELLED'},
        storeId: storeId,
      );
      if (res != null) {
        final index = _userOrders.indexWhere(
          (o) => o.id == orderId || o.orderId == orderId,
        );
        if (index != -1) {
          final updated = OrderModel.fromJson(res);
          _userOrders[index] = updated;
          await StorageService.saveRecentOrders(_userOrders);
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

  /// Rate and review a delivered order
  Future<bool> rateOrder({
    required String orderId,
    required double rating,
    String? review,
    String? storeId,
  }) async {
    try {
      final res = await _apiService.post(
        '/orders/$orderId/rate',
        body: {
          'rating': rating,
          'review': review?.trim() ?? '',
        },
        storeId: storeId ?? ApiConfig.defaultStoreId,
      );

      if (res != null) {
        final index = _userOrders.indexWhere(
          (o) => o.id == orderId || o.orderId == orderId,
        );
        if (index != -1) {
          final old = _userOrders[index];
          _userOrders[index] = OrderModel(
            id: old.id,
            orderId: old.orderId,
            userId: old.userId,
            customerName: old.customerName,
            customerPhone: old.customerPhone,
            deliveryAddress: old.deliveryAddress,
            items: old.items,
            itemTotal: old.itemTotal,
            deliveryFee: old.deliveryFee,
            deliveryTip: old.deliveryTip,
            couponCode: old.couponCode,
            taxAmount: old.taxAmount,
            discountAmount: old.discountAmount,
            totalAmount: old.totalAmount,
            status: old.status,
            paymentMethod: old.paymentMethod,
            paymentStatus: old.paymentStatus,
            assignedRider: old.assignedRider,
            deliveryInstructions: old.deliveryInstructions,
            rating: rating,
            review: review?.trim(),
            createdAt: old.createdAt,
          );
          await StorageService.saveRecentOrders(_userOrders);
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

  /// 1-Tap Re-order: Adds available products from past order into current cart
  int reorder({
    required OrderModel pastOrder,
    required CartProvider cart,
    required List<ProductModel> catalogProducts,
  }) {
    int readdedCount = 0;

    for (final orderItem in pastOrder.items) {
      try {
        final product = catalogProducts.firstWhere(
          (p) => p.id == orderItem.productId,
        );

        if (!product.isAvailable) continue;

        // Find matching variant size
        final variant = product.variants.firstWhere(
          (v) => v.size == orderItem.variantSize,
          orElse: () => product.variants.isNotEmpty ? product.variants.first : throw 'No variant',
        );

        if (variant.stock > 0) {
          for (int i = 0; i < orderItem.quantity; i++) {
            cart.addItem(product, variant);
          }
          readdedCount++;
        }
      } catch (_) {
        // Skip unavailable items gracefully
      }
    }

    return readdedCount;
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
      final String humanReadableOrderId =
          "UB-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
      final String effectiveStoreId = (storeId.isNotEmpty)
          ? storeId
          : ApiConfig.defaultStoreId;

      // Double-tap prevention idempotency key
      final String idempotencyKey =
          "idemp_${user.id}_${DateTime.now().millisecondsSinceEpoch}_${cart.itemList.length}";

      final Map<String, dynamic> body = {
        'orderId': humanReadableOrderId,
        'storeId': effectiveStoreId,
        'user': user.id,
        'customerName': user.name,
        'customerPhone': user.phone,
        'deliveryAddress': deliveryAddress.toJson(),
        'items': cart.itemList
            .map(
              (i) => {
                'storeId': effectiveStoreId,
                'product': i.product.id,
                'name': i.product.name,
                'variantSize': i.selectedVariant.size,
                'quantity': i.quantity,
                'priceAtPurchase': i.selectedVariant.price,
                'imageUrl': i.product.images.isNotEmpty
                    ? i.product.images.first
                    : '',
              },
            )
            .toList(),
        'itemTotal': cart.itemTotal,
        'deliveryFee': cart.deliveryFee,
        'deliveryTip': cart.deliveryTip,
        'deliveryInstructions': [
          ...cart.deliveryInstructions,
          if (cart.deliveryNote.trim().isNotEmpty) "Note: ${cart.deliveryNote.trim()}",
        ],
        'deliveryNote': cart.deliveryNote.trim(),
        'otp': (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString(),
        'taxAmount': 0.0,
        'discountAmount': cart.discountAmount,
        'couponCode': cart.couponCode,
        'totalAmount': cart.grandTotal,
        'status': 'PENDING',
        'paymentMethod': paymentMethod,
        'paymentStatus': 'PENDING',
        'idempotencyKey': idempotencyKey,
      };

      final res = await _apiService.post(
        '/orders',
        body: body,
        storeId: effectiveStoreId,
      );
      final OrderModel newOrder = OrderModel.fromJson(res);
      _currentPlacingOrder = newOrder;
      _userOrders.insert(0, newOrder);

      await StorageService.saveRecentOrders(_userOrders);

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

  @override
  void dispose() {
    stopLiveTracking();
    super.dispose();
  }
}
