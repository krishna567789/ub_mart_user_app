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
    if (_settings == null || _settings!.primaryColor.isEmpty) return const Color(0xFF0C831F); // Default Green
    return _parseHex(_settings!.primaryColor);
  }

  Color getAccentColor() {
    if (_settings == null || _settings!.accentColor.isEmpty) return const Color(0xFFFF6D00); // Default Orange
    return _parseHex(_settings!.accentColor);
  }

  Color getBackgroundColor() {
    if (_settings == null || _settings!.backgroundColor.isEmpty) return const Color(0xFFF4F6F8);
    return _parseHex(_settings!.backgroundColor);
  }

  Color getTextPrimaryColor() {
    if (_settings == null || _settings!.textPrimaryColor.isEmpty) return const Color(0xFF1F2937);
    return _parseHex(_settings!.textPrimaryColor);
  }

  Color _parseHex(String hexColor) {
    String hex = hexColor.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add 100% opacity
    }
    try {
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF0C831F); // Fallback to green
    }
  }
}
