import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  // Use the global apiService instance
  // final ApiService _apiService = ApiService();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadSavedUser() async {
    _user = await StorageService.getUser();
    final token = await StorageService.getAuthToken();
    if (token != null) {
      apiService.setAuthToken(token);
    }
    if (_user != null) {
      // Refresh user details from backend in background
      refreshUser();
    }
    notifyListeners();
  }

  String? _debugOtp;
  String? get debugOtp => _debugOtp;

  // Send OTP (Step 1)
  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _debugOtp = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/send-otp', body: {'phone': phone});
      if (response != null && response['success'] == true) {
        final returnedOtp = response['otp'] ?? response['debugOtp'];
        if (returnedOtp != null) {
          _debugOtp = returnedOtp.toString();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw Exception('Failed to send OTP.');
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Verify OTP (Step 2)
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
    String? name,
    required String storeId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> body = {
        'phone': phone,
        'otp': otp,
        if (name != null && name.isNotEmpty) 'name': name,
        'storeId': storeId,
      };

      final response = await apiService.post('/auth/verify-otp', body: body, storeId: storeId);

      if (response != null && response['success'] == true && response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
        await StorageService.saveUser(_user!);
        
        // Save Auth Token if provided
        if (response['token'] != null) {
          final token = response['token'];
          apiService.setAuthToken(token);
          await StorageService.saveAuthToken(token);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response?['error'] ?? 'Failed to verify OTP.');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    try {
      final data = await apiService.get('/users/${_user!.id}');
      if (data != null && data is Map<String, dynamic>) {
        _user = UserModel.fromJson(data);
        await StorageService.saveUser(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addAddress(AddressModel newAddress) async {
    if (_user == null) return;
    final updatedAddresses = List<AddressModel>.from(_user!.addresses)..add(newAddress);
    await _updateAddresses(updatedAddresses);
  }

  Future<void> deleteAddress(int index) async {
    if (_user == null || index < 0 || index >= _user!.addresses.length) return;
    final updatedAddresses = List<AddressModel>.from(_user!.addresses)..removeAt(index);
    await _updateAddresses(updatedAddresses);
  }

  Future<void> setDefaultAddress(int index) async {
    if (_user == null || index <= 0 || index >= _user!.addresses.length) return;
    final updatedAddresses = List<AddressModel>.from(_user!.addresses);
    final selected = updatedAddresses.removeAt(index);
    updatedAddresses.insert(0, selected);
    await _updateAddresses(updatedAddresses);
  }

  Future<void> updateAddress(int index, AddressModel updatedAddress) async {
    if (_user == null || index < 0 || index >= _user!.addresses.length) return;
    final updatedAddresses = List<AddressModel>.from(_user!.addresses);
    updatedAddresses[index] = updatedAddress;
    await _updateAddresses(updatedAddresses);
  }

  Future<void> _updateAddresses(List<AddressModel> updatedAddresses) async {
    if (_user == null) return;

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

    try {
      await apiService.put(
        '/users/${_user!.id}',
        body: {'addresses': updatedAddresses.map((a) => a.toJson()).toList()},
        storeId: _user!.storeId,
      );
    } catch (e) {
      debugPrint('Failed to sync addresses with backend: $e');
    }
  }

  Future<void> logout() async {
    _user = null;
    apiService.setAuthToken('');
    await StorageService.clearUser();
    notifyListeners();
  }
}
