import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../models/main_category_model.dart';
import '../models/homepage_section_model.dart';
import '../services/api_service.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<BannerModel> _banners = [];
  List<MainCategoryModel> _mainCategories = [];
  List<HomepageSectionModel> _homepageSections = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BannerModel> get banners => _banners;
  List<MainCategoryModel> get mainCategories => _mainCategories;
  List<HomepageSectionModel> get homepageSections => _homepageSections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHomeData(String storeId) async {
    if (storeId.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch Banners, Main Categories, and Dynamic Homepage Sections in parallel
      final results = await Future.wait([
        _apiService.get('/banners', storeId: storeId),
        _apiService.get('/main-categories', storeId: storeId),
        _apiService.get('/homepage', storeId: storeId),
      ]);

      if (results[0] is List) {
        _banners = (results[0] as List).map((b) => BannerModel.fromJson(b)).toList();
      }

      if (results[1] is List) {
        _mainCategories = (results[1] as List).map((mc) => MainCategoryModel.fromJson(mc)).toList();
      }

      if (results[2] is List) {
        _homepageSections = (results[2] as List)
            .map((s) => HomepageSectionModel.fromJson(s))
            .where((s) => s.isActive)
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
