import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:un_mart_user_app/main.dart';
import 'package:un_mart_user_app/providers/home_provider.dart';
import 'package:un_mart_user_app/providers/cart_provider.dart';
import 'package:un_mart_user_app/providers/product_provider.dart';
import 'package:un_mart_user_app/providers/auth_provider.dart';
import 'package:un_mart_user_app/providers/order_provider.dart';
import 'package:un_mart_user_app/providers/store_provider.dart';
import 'package:un_mart_user_app/providers/settings_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => HomeProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => StoreProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const MyApp(),
      ),
    );
  });
}
