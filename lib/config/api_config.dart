class ApiConfig {
  // Live Production Backend Server URL
  static const String liveBaseUrl = "https://ub-mart-admin.vercel.app/api";

  static String customBaseUrl = "";

  static String get baseUrl {
    if (customBaseUrl.isNotEmpty) return customBaseUrl;
    return liveBaseUrl;
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
