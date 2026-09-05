import 'package:flutter/foundation.dart';

class ApiConfig {
  static String customBaseUrl = "";

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) return customBaseUrl;
    if (kIsWeb) return "http://localhost:3000/api";
    // Default Android Emulator IP connecting to host localhost:3000
    return "http://10.0.2.2:3000/api";
  }

  static String defaultStoreId = "";

  static Map<String, String> headers({String? storeId}) {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final activeStoreId = (storeId != null && storeId.isNotEmpty)
        ? storeId
        : defaultStoreId;
    if (activeStoreId.isNotEmpty) {
      headers['x-store-id'] = activeStoreId;
    }
    return headers;
  }
}
