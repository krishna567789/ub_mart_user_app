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
      final response = await apiService.get(ApiConstants.homepage);
      print("HOMEPAGE RESPONSE TYPE: ${response.runtimeType}");
      print("HOMEPAGE RESPONSE: $response");

      if (response != null && response is List) {
        sections = response.map((e) => HomepageSection.fromJson(e)).toList();
        print("PARSED SECTIONS COUNT: ${sections.length}");
      } else {
        error =
            "Response is not a list! Type: ${response.runtimeType}, Data: $response";
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
