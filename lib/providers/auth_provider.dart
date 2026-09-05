import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedUser() async {
    _user = await StorageService.getUser();
    notifyListeners();
  }

  // Quick Login / Sign up with Phone & Name
  Future<bool> loginOrRegister({
    required String name,
    required String phone,
    String? email,
    required String storeId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if user already exists or create new user in /api/users
      // In this backend, users are stored in User collection per storeId
      final usersData = await _apiService.get('/users', storeId: storeId);
      UserModel? existingUser;

      if (usersData is List) {
        for (var u in usersData) {
          if (u['phone'] == phone) {
            existingUser = UserModel.fromJson(u);
            break;
          }
        }
      }

      if (existingUser != null) {
        _user = existingUser;
      } else {
        // Register new user via backend create user or POST order / custom logic
        // We simulate user record locally and save
        _user = UserModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          storeId: storeId,
          name: name,
          phone: phone,
          email: email,
          walletBalance: 0.0,
          addresses: [],
        );
      }

      await StorageService.saveUser(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> addAddress(AddressModel newAddress) async {
    if (_user == null) return;

    final updatedAddresses = List<AddressModel>.from(_user!.addresses)..add(newAddress);
    _user = UserModel(
      id: _user!.id,
      storeId: _user!.storeId,
      name: _user!.name,
      phone: _user!.phone,
      email: _user!.email,
      walletBalance: _user!.walletBalance,
      addresses: updatedAddresses,
    );

    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    await StorageService.clearUser();
    notifyListeners();
  }
}
