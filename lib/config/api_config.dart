import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable base URL:
  // Android Emulator: "http://10.0.2.2:3000/api"
  // iOS Simulator / Web: "http://localhost:3000/api"
  // Physical Device: Change to your Machine IP e.g. "http://192.168.x.x:3000/api"
  static String customBaseUrl = "";

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) return customBaseUrl;
    if (kIsWeb) return "http://localhost:3000/api";
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
