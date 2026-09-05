import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/sub_category_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CategoryModel> _categories = [];
  List<SubCategoryModel> _subCategories = [];
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> get categories => _categories;
  List<SubCategoryModel> get subCategories => _subCategories;
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCategories(String storeId) async {
    try {
      final res = await _apiService.get('/categories', storeId: storeId);
      if (res is List) {
        _categories = res.map((c) => CategoryModel.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> fetchSubCategories(String storeId, {String? categoryId}) async {
    try {
      final Map<String, String> query = {};
      if (categoryId != null && categoryId.isNotEmpty) {
        query['category'] = categoryId;
      }
      final res = await _apiService.get('/sub-categories', storeId: storeId, queryParams: query);
      if (res is List) {
        _subCategories = res.map((sc) => SubCategoryModel.fromJson(sc)).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  Future<void> fetchProducts(String storeId, {String? subCategoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> query = {};
      if (subCategoryId != null && subCategoryId.isNotEmpty) {
        query['subCategory'] = subCategoryId;
      }

      final res = await _apiService.get('/products', storeId: storeId, queryParams: query);
      if (res is List) {
        _products = res.map((p) => ProductModel.fromJson(p)).toList();
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
}
