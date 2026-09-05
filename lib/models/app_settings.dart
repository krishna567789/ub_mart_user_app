import 'package:flutter/material.dart';

class AnnouncementBar {
  final bool isActive;
  final String text;
  final String bgColor;

  AnnouncementBar({
    required this.isActive,
    required this.text,
    required this.bgColor,
  });

  factory AnnouncementBar.fromJson(Map<String, dynamic> json) {
    return AnnouncementBar(
      isActive: json['isActive'] ?? false,
      text: json['text'] ?? '',
      bgColor: json['bgColor'] ?? '#ef4444',
    );
  }
}

class SeasonalTheme {
  final String mode;
  final String intensity;
  final bool showInApp;

  SeasonalTheme({
    required this.mode,
    required this.intensity,
    required this.showInApp,
  });

  factory SeasonalTheme.fromJson(Map<String, dynamic> json) {
    return SeasonalTheme(
      mode: json['mode'] ?? 'NONE',
      intensity: json['intensity'] ?? 'MEDIUM',
      showInApp: json['showInApp'] ?? true,
    );
  }
}

class AppSettings {
  final String storeName;
  final bool isStoreOpen;
  final String storeClosedMessage;
  final int minimumOrderValue;
  final int baseDeliveryFee;
  final String primaryColor;
  final AnnouncementBar announcementBar;
  final SeasonalTheme seasonalTheme;
  final String currencySymbol;

  AppSettings({
    required this.storeName,
    required this.isStoreOpen,
    required this.storeClosedMessage,
    required this.minimumOrderValue,
    required this.baseDeliveryFee,
    required this.primaryColor,
    required this.announcementBar,
    required this.seasonalTheme,
    required this.currencySymbol,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      storeName: json['storeName'] ?? 'UB Mart',
      isStoreOpen: json['isStoreOpen'] ?? true,
      storeClosedMessage: json['storeClosedMessage'] ?? '',
      minimumOrderValue: json['minimumOrderValue'] ?? 0,
      baseDeliveryFee: json['baseDeliveryFee'] ?? 0,
      primaryColor: json['primaryColor'] ?? '#6366f1',
      announcementBar: AnnouncementBar.fromJson(json['announcementBar'] ?? {}),
      seasonalTheme: SeasonalTheme.fromJson(json['seasonalTheme'] ?? {}),
      currencySymbol: json['currencySymbol'] ?? '₹',
    );
  }
}
