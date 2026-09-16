import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import '../models/order_model.dart';

class StorageService {
  static const String keySelectedStore = 'selected_store';
  static const String keyUser = 'user_data';
  static const String keyAuthToken = 'auth_token';
  static const String keyRecentOrders = 'recent_orders_cache';

  static Future<void> saveSelectedStore(StoreModel store) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keySelectedStore, jsonEncode(store.toJson()));
  }

  static Future<StoreModel?> getSelectedStore() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keySelectedStore);
    if (str != null) {
      try {
        return StoreModel.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUser, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyUser);
    if (str != null) {
      try {
        return UserModel.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyUser);
    await prefs.remove(keyAuthToken);
  }

  static Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyAuthToken, token);
  }

  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyAuthToken);
  }

  static Future<void> saveRecentOrders(List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = orders.take(20).map((o) => o.toJson()).toList();
    await prefs.setString(keyRecentOrders, jsonEncode(jsonList));
  }

  static Future<List<OrderModel>> getRecentOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(keyRecentOrders);
    if (str != null) {
      try {
        final List<dynamic> decoded = jsonDecode(str);
        return decoded
            .map((item) => OrderModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (_) {}
    }
    return [];
  }
}
