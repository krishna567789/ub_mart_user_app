class ApiConfig {
  static const String baseUrl = "http://10.0.2.2:3000/api";
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
