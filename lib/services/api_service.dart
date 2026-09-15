import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import '../config/api_config.dart';
import 'package:flutter/foundation.dart';

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
    
    final finalStoreId = customStoreId ?? _storeId ?? ApiConfig.defaultStoreId;
    if (finalStoreId.isNotEmpty) {
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
    _logRequest('GET', url, headers);

    try {
      final response = await _client.get(url, headers: headers);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, String? storeId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = _getHeaders(storeId);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('POST', url, headers, jsonBody);

    try {
      final response = await _client.post(url, headers: headers, body: jsonBody);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body, String? storeId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = _getHeaders(storeId);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('PUT', url, headers, jsonBody);

    try {
      final response = await _client.put(url, headers: headers, body: jsonBody);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body, String? storeId}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = _getHeaders(storeId);
    final jsonBody = body != null ? jsonEncode(body) : null;
    _logRequest('PATCH', url, headers, jsonBody);

    try {
      final response = await _client.patch(url, headers: headers, body: jsonBody);
      _logResponse(response);
      return _processResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> delete(String endpoint, {String? storeId, Map<String, String>? queryParams}) async {
    Uri url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }
    
    final headers = _getHeaders(storeId);
    _logRequest('DELETE', url, headers);

    try {
      final response = await _client.delete(url, headers: headers);
      _logResponse(response);
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

  void _logRequest(String method, Uri url, Map<String, String> headers, [String? body]) {
    if (!kDebugMode) return;
    debugPrint('\n================ API REQUEST ================');
    debugPrint('[$method] $url');
    debugPrint('HEADERS: $headers');
    if (body != null) {
      try {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
        debugPrint('BODY: \n$prettyJson');
      } catch (_) {
        debugPrint('BODY: $body');
      }
    }
    debugPrint('=============================================\n');
  }

  void _logResponse(http.Response response) {
    if (!kDebugMode) return;
    debugPrint('\n================ API RESPONSE ===============');
    debugPrint('[${response.statusCode}] ${response.request?.url}');
    if (response.body.isNotEmpty) {
      try {
        final prettyJson = const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body));
        debugPrint('BODY: \n$prettyJson');
      } catch (_) {
        debugPrint('BODY: ${response.body}');
      }
    }
    debugPrint('=============================================\n');
  }
}

final apiService = ApiService();
