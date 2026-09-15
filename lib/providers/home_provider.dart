import 'package:flutter/material.dart';
import '../models/homepage_section.dart';
import '../models/category.dart'; // Ensure correct import
import '../services/api_service.dart';
import '../utils/api_constants.dart';

class HomeProvider extends ChangeNotifier {
  List<HomepageSection> sections = [];
  List<Category> mainCategories = []; // Added for backward compatibility
  bool isLoading = false;
  String? error;

  Future<void> fetchHomepage() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final futures = await Future.wait([
        apiService.get(ApiConstants.homepage),
        apiService.get(ApiConstants.mainCategories),
        apiService.get(ApiConstants.categories), // Fetch subcategories as fallback
      ]);

      final homepageResponse = futures[0];
      final mainCatsResponse = futures[1];
      final categoriesResponse = futures[2];

      List<Category> fallbackCategories = [];
      if (categoriesResponse != null && categoriesResponse is List) {
        fallbackCategories = categoriesResponse.map((e) => Category.fromJson(e)).toList();
      }

      if (homepageResponse != null && homepageResponse is List) {
        sections = homepageResponse.map((e) => HomepageSection.fromJson(e)).toList();
        
        // Fix for Vercel API cache returning empty categoryIds
        for (var section in sections) {
          if (section.type == 'CATEGORY_GRID' && section.categories.isEmpty) {
            section.categories.addAll(fallbackCategories);
          }
        }
      }

      if (mainCatsResponse != null && mainCatsResponse is List) {
        mainCategories = mainCatsResponse.map((e) => Category.fromJson(e)).toList();
      }

    } catch (e, stacktrace) {
      error = e.toString();
      print("ERROR PARSING HOMEPAGE: $e\n$stacktrace");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
