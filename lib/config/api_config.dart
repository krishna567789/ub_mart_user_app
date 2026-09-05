import 'package:flutter/foundation.dart';

class ApiConfig {
  static String customBaseUrl = "";

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) return customBaseUrl;
    if (kIsWeb) return "https://ubmart-admin.vercel.app/api";
    return "https://ubmart-admin.vercel.app/api";
  }

  static String defaultStoreId = "6a9bc0af2b4db103cebe7c04";

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
