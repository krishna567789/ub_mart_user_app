import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FavoritesProvider with ChangeNotifier {
  String? _userId;
  final Set<String> _favoriteIds = {};
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = false;

  Set<String> get favoriteIds => _favoriteIds;
  List<ProductModel> get favoriteProducts => _favoriteProducts;
  bool get isLoading => _isLoading;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  Future<void> loadFavoritesFromBackend() async {
    final user = await StorageService.getUser();
    if (user == null) return;
    _userId = user.id;
    
    _isLoading = true;
    notifyListeners();

    try {
      final res = await apiService.get('/users/$_userId/favorites');
      if (res != null && res['success'] == true) {
        final List faves = res['favorites'] ?? [];
        _favoriteIds.clear();
        _favoriteIds.addAll(faves.cast<String>());

        if (res['favoriteProducts'] != null && res['favoriteProducts'] is List) {
          final List prods = res['favoriteProducts'];
          _favoriteProducts = prods
              .whereType<Map>()
              .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String productId, [ProductModel? product]) async {
    if (_userId == null) {
      final user = await StorageService.getUser();
      if (user != null) _userId = user.id;
    }
    
    if (_userId == null) {
      // Allow local toggle if not logged in
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
      } else {
        _favoriteIds.add(productId);
        if (product != null) _favoriteProducts.add(product);
      }
      notifyListeners();
      return;
    }

    final isFav = _favoriteIds.contains(productId);
    final action = isFav ? 'REMOVE' : 'ADD';

    // Optimistic UI update
    if (isFav) {
      _favoriteIds.remove(productId);
      _favoriteProducts.removeWhere((p) => p.id == productId);
    } else {
      _favoriteIds.add(productId);
      if (product != null) _favoriteProducts.add(product);
    }
    notifyListeners();

    try {
      final res = await apiService.put(
        '/users/$_userId/favorites',
        body: {'productId': productId, 'action': action},
      );
      if (res == null || res['success'] != true) {
        // Revert on failure
        if (isFav) {
          _favoriteIds.add(productId);
          if (product != null) _favoriteProducts.add(product);
        } else {
          _favoriteIds.remove(productId);
          _favoriteProducts.removeWhere((p) => p.id == productId);
        }
        notifyListeners();
      } else if (res['favoriteProducts'] != null && res['favoriteProducts'] is List) {
        final List prods = res['favoriteProducts'];
        _favoriteProducts = prods
            .whereType<Map>()
            .map((p) => ProductModel.fromJson(Map<String, dynamic>.from(p)))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on failure
      if (isFav) {
        _favoriteIds.add(productId);
        if (product != null) _favoriteProducts.add(product);
      } else {
        _favoriteIds.remove(productId);
        _favoriteProducts.removeWhere((p) => p.id == productId);
      }
      notifyListeners();
    }
  }

  void clearFavorites() {
    _favoriteIds.clear();
    _favoriteProducts.clear();
    notifyListeners();
  }
}

