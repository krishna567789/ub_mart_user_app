import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/home_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/store_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'theme/seasonal_overlay.dart';
import 'services/api_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  apiService.setStoreId('6a9bc0af2b4db103cebe7c04');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..fetchSettings()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final dynamicColor = settingsProvider.getPrimaryColor();
        final seasonMode = settingsProvider.settings?.seasonalTheme.mode ?? 'NONE';
        final intensity = settingsProvider.settings?.seasonalTheme.intensity ?? 'MEDIUM';
        final showInApp = settingsProvider.settings?.seasonalTheme.showInApp ?? true;

        return MaterialApp(
          title: 'UB Mart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildDynamicTheme(dynamicColor),
          home: showInApp 
            ? SeasonalOverlay(
                seasonMode: seasonMode,
                intensity: intensity,
                child: const MainNavigationScreen(),
              )
            : const MainNavigationScreen(),
        );
      },
    );
  }
}
