import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';

class StorageService {
  static const String keySelectedStore = 'selected_store';
  static const String keyUser = 'user_data';

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
  }
}
