import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/api_service.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings? _settings;
  bool _isLoading = false;
  String? _error;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await apiService.get('/settings');
      if (data != null) {
        _settings = AppSettings.fromJson(data);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Color getPrimaryColor() {
    if (_settings == null || _settings!.primaryColor.isEmpty) return const Color(0xFF6366f1);
    String hex = _settings!.primaryColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
