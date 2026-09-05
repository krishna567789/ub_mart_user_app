import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  final http.Client client;

  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<dynamic> get(String endpoint, {String? storeId, Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = ApiConfig.headers(storeId: storeId);
    final response = await client.get(uri, headers: headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, {required Map<String, dynamic> body, String? storeId}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = ApiConfig.headers(storeId: storeId);
    final response = await client.post(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, {required Map<String, dynamic> body, String? storeId}) async {
    final uri = Uri.parse("${ApiConfig.baseUrl}$endpoint");
    final headers = ApiConfig.headers(storeId: storeId);
    final response = await client.put(uri, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      dynamic errorBody;
      try {
        errorBody = jsonDecode(response.body);
      } catch (_) {
        errorBody = response.body;
      }
      final msg = (errorBody is Map && errorBody.containsKey('error'))
          ? errorBody['error']
          : "Server Error (${response.statusCode})";
      throw Exception(msg);
    }
  }
}
