import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class FavoritesProvider with ChangeNotifier {
  String? _userId;
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;

  Set<String> get favoriteIds => _favoriteIds;
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
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String productId) async {
    if (_userId == null) {
      final user = await StorageService.getUser();
      if (user != null) _userId = user.id;
    }
    
    if (_userId == null) {
      // Allow local toggle if not logged in (will be lost on restart)
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
      notifyListeners();
      return;
    }

    final isFav = _favoriteIds.contains(productId);
    final action = isFav ? 'REMOVE' : 'ADD';

    // Optimistic UI update
    if (isFav) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
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
        } else {
          _favoriteIds.remove(productId);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      // Revert on failure
      if (isFav) {
        _favoriteIds.add(productId);
      } else {
        _favoriteIds.remove(productId);
      }
      notifyListeners();
    }
  }

  void clearFavorites() {
    _favoriteIds.clear();
    notifyListeners();
  }
}
