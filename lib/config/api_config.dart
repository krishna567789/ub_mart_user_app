class ApiConfig {
  // Use 10.0.2.2 for Android Emulator, or localhost for iOS simulator / web, or your local machine IP for physical device
  static const String baseUrl = "http://10.0.2.2:3000/api";
  
  // Default store ID if none selected (can be overridden dynamically via StoreProvider)
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
