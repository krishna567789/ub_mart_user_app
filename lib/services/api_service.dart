import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();
  
  String? _storeId;
  String? _authToken;

  void setStoreId(String storeId) {
    _storeId = storeId;
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> _getHeaders(String? customStoreId) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    final finalStoreId = customStoreId ?? _storeId;
    if (finalStoreId != null) {
      headers['x-store-id'] = finalStoreId;
    }
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  Future<dynamic> get(String endpoint, {String? storeId, Map<String, String>? queryParams}) async {
    Uri url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    
    final headers = _getHeaders(storeId);
    print("API GET URL: $url");
    print("API GET HEADERS: $headers");

    try {
      final response = await _client.get(url, headers: headers);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, String? storeId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(storeId),
        body: body != null ? jsonEncode(body) : null,
      );
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String message = 'Unknown error occurred';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['error'] ?? message;
      } catch (_) {}
      throw Exception('API Error (${response.statusCode}): $message');
    }
  }
}

final apiService = ApiService();
