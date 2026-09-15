import '../config/api_config.dart';

class ApiConstants {
  static String get baseUrl => ApiConfig.baseUrl;
  static const String homepage = '/homepage';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String mainCategories = '/main-categories';
  static const String login = '/auth/login';
}
