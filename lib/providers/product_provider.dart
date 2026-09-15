import 'package:flutter/material.dart';
import '../models/main_category_model.dart';
import '../models/category_model.dart';
import '../models/sub_category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MainCategoryModel> _mainCategories = [];
  List<CategoryModel> _categories = [];
  List<SubCategoryModel> _subCategories = [];
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MainCategoryModel> get mainCategories => _mainCategories;
  List<CategoryModel> get categories => _categories;
  List<SubCategoryModel> get subCategories => _subCategories;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMainCategoriesTree(String storeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      dynamic res;
      try {
        res = await _apiService.get('/main-categories/tree', storeId: storeId);
      } catch (_) {
        res = await _apiService.get('/categories/tree', storeId: storeId);
      }

      if (res is List) {
        if (res.isNotEmpty && res.first is Map && (res.first as Map).containsKey('categories')) {
          _mainCategories = res
              .map((m) => MainCategoryModel.fromJson(m is Map ? Map<String, dynamic>.from(m) : <String, dynamic>{}))
              .toList();
          _categories = _mainCategories.expand((m) => m.categories).toList();
        } else {
          _categories = res
              .map((c) => CategoryModel.fromJson(c is Map ? Map<String, dynamic>.from(c) : <String, dynamic>{}))
              .toList();

          _mainCategories = [
            MainCategoryModel(
              id: 'all',
              name: 'All Categories',
              image: '',
              categories: _categories,
            ),
          ];
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories(String storeId) async {
    await fetchMainCategoriesTree(storeId);
  }

  Future<void> fetchSubCategories(String storeId, {String? categoryId}) async {
    _subCategories = [];
    notifyListeners();

    try {
      if (categoryId != null && categoryId.isNotEmpty && _categories.isNotEmpty) {
        final matches = _categories.where((c) => c.id == categoryId).toList();
        if (matches.isNotEmpty && matches.first.subCategories.isNotEmpty) {
          _subCategories = matches.first.subCategories;
          notifyListeners();
          return;
        }
      }

      final Map<String, String> query = {};
      if (categoryId != null && categoryId.isNotEmpty) {
        query['category'] = categoryId;
      }
      final res = await _apiService.get('/sub-categories', storeId: storeId, queryParams: query);
      if (res is List) {
        _subCategories = res
            .map((sc) => SubCategoryModel.fromJson(sc is Map ? Map<String, dynamic>.from(sc) : <String, dynamic>{}))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> fetchProducts(
    String storeId, {
    String? subCategoryId,
    String? categoryId,
    String? search,
    String? badge,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> query = {};
      if (subCategoryId != null && subCategoryId.isNotEmpty) {
        query['subCategory'] = subCategoryId;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        query['category'] = categoryId;
      }
      if (search != null && search.isNotEmpty) {
        query['search'] = search;
      }
      if (badge != null && badge.isNotEmpty) {
        query['badge'] = badge;
      }

      final res = await _apiService.get('/products', storeId: storeId, queryParams: query);
      if (res is List) {
        _products = res
            .map((p) => ProductModel.fromJson(p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{}))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;
    final q = query.toLowerCase();
    return _products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          (p.brand != null && p.brand!.toLowerCase().contains(q)) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  Future<List<ProductModel>> fetchSimilarProducts(String productId) async {
    try {
      final res = await _apiService.get('/products/$productId/similar');
      if (res is List) {
        return res
            .map((p) => ProductModel.fromJson(p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{}))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching similar products: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchProductReviews(String productId) async {
    try {
      final res = await _apiService.get('/products/$productId/reviews');
      if (res is Map<String, dynamic>) {
        final List<ReviewModel> reviews = (res['reviews'] as List<dynamic>?)
                ?.map((r) => ReviewModel.fromJson(r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{}))
                .toList() ??
            [];
        return {
          'rating': (res['rating'] ?? 4.6).toDouble(),
          'reviewCount': (res['reviewCount'] ?? reviews.length) as int,
          'reviews': reviews,
        };
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    }
    return {
      'rating': 4.6,
      'reviewCount': 0,
      'reviews': <ReviewModel>[],
    };
  }

  Future<bool> submitProductReview(
    String productId, {
    required String userName,
    required double rating,
    required String comment,
  }) async {
    try {
      final res = await _apiService.post(
        '/products/$productId/reviews',
        body: {
          'userName': userName,
          'rating': rating,
          'comment': comment,
        },
      );
      if (res != null && res['success'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
    }
    return false;
  }
}
