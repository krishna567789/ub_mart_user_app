

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
  
  // Dynamic UI Colors from Admin
  final String primaryColor;
  final String accentColor;
  final String backgroundColor;
  final String textPrimaryColor;

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
    required this.accentColor,
    required this.backgroundColor,
    required this.textPrimaryColor,
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
      primaryColor: json['primaryColor'] ?? '#0C831F',
      accentColor: json['accentColor'] ?? '#FF6D00',
      backgroundColor: json['backgroundColor'] ?? '#F4F6F8',
      textPrimaryColor: json['textPrimaryColor'] ?? '#1F2937',
      announcementBar: AnnouncementBar.fromJson(json['announcementBar'] ?? {}),
      seasonalTheme: SeasonalTheme.fromJson(json['seasonalTheme'] ?? {}),
      currencySymbol: json['currencySymbol'] ?? '₹',
    );
  }
}
