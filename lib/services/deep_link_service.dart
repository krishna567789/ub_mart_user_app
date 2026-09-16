import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../screens/product_detail_screen.dart';
import '../screens/order_tracking_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/search/product_search_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/wishlist_screen.dart';
import '../widgets/custom_text.dart';
import '../theme/app_theme.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _isHandling = false;

  static const String webDomain = "udaybharatmarts.com";
  static const String adminDomain = "ubmart-admin.vercel.app";
  static const String customScheme = "ubmart";

  /// Initialize Deep Link listeners for cold launch and background runtime links
  Future<void> init() async {
    // 1. Listen to incoming links while app is in foreground / background
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DeepLinkService] Incoming runtime link: $uri');
        handleUri(uri);
      },
      onError: (err) {
        debugPrint('[DeepLinkService] Stream error: $err');
      },
    );

    // 2. Check initial link if app was cold-launched via link click
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DeepLinkService] Cold launch initial link: $initialUri');
        // Small delay to ensure navigator context is mounted
        Future.delayed(const Duration(milliseconds: 600), () {
          handleUri(initialUri);
        });
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Failed to get initial link: $e');
    }
  }

  /// Process and route any incoming URI (custom scheme or Universal link)
  Future<void> handleUri(Uri uri) async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('[DeepLinkService] Navigator context not ready. Retrying in 400ms...');
        await Future.delayed(const Duration(milliseconds: 400));
        _isHandling = false;
        if (navigatorKey.currentContext != null) {
          handleUri(uri);
        }
        return;
      }

      final scheme = uri.scheme.toLowerCase();
      final host = uri.host.toLowerCase();
      final pathSegments = uri.pathSegments;

      debugPrint('[DeepLinkService] Routing scheme: $scheme, host: $host, path: ${uri.path}');

      // Validate scheme or domain
      final isCustomScheme = scheme == customScheme;
      final isWebDomain = host == webDomain || host == "www.$webDomain" || host == adminDomain;

      if (!isCustomScheme && !isWebDomain) {
        debugPrint('[DeepLinkService] Unrecognized link host/scheme: $uri');
        return;
      }

      // ── ROUTE 1: Product Detail (ubmart://product/<id> or https://domain/product/<id>) ──
      if ((isCustomScheme && host == 'product') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'product')) {
        String productId = '';
        if (isCustomScheme && host == 'product') {
          productId = pathSegments.isNotEmpty ? pathSegments[0] : '';
        } else if (pathSegments.length >= 2) {
          productId = pathSegments[1];
        }

        if (productId.isNotEmpty) {
          _navigateToProduct(context, productId);
          return;
        }
      }

      // ── ROUTE 2: Order Tracking (ubmart://order/<id> or https://domain/order/<id>) ──
      if ((isCustomScheme && host == 'order') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'order')) {
        String orderId = '';
        if (isCustomScheme && host == 'order') {
          orderId = pathSegments.isNotEmpty ? pathSegments[0] : '';
        } else if (pathSegments.length >= 2) {
          orderId = pathSegments[1];
        }

        if (orderId.isNotEmpty) {
          _navigateToOrder(context, orderId);
          return;
        }
      }

      // ── ROUTE 3: Cart / Checkout (ubmart://cart or https://domain/cart) ──
      if ((isCustomScheme && host == 'cart') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'cart')) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
        return;
      }

      // ── ROUTE 4: Search (ubmart://search?q=... or https://domain/search?q=...) ──
      if ((isCustomScheme && host == 'search') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'search')) {
        final query = uri.queryParameters['q'] ?? uri.queryParameters['search'] ?? '';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductSearchScreen(initialQuery: query, autoFocus: false),
          ),
        );
        return;
      }

      // ── ROUTE 5: Category (ubmart://category/<id> or https://domain/category/<id>) ──
      if ((isCustomScheme && host == 'category') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'category')) {
        String catId = '';
        if (isCustomScheme && host == 'category') {
          catId = pathSegments.isNotEmpty ? pathSegments[0] : '';
        } else if (pathSegments.length >= 2) {
          catId = pathSegments[1];
        }

        final title = uri.queryParameters['name'] ?? 'Products';
        if (catId.isNotEmpty) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductListScreen(
                categoryId: catId,
                title: title,
              ),
            ),
          );
          return;
        }
      }

      // ── ROUTE 6: Wishlist (ubmart://wishlist or https://domain/wishlist) ──
      if ((isCustomScheme && host == 'wishlist') ||
          (pathSegments.isNotEmpty && pathSegments[0] == 'wishlist')) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const WishlistScreen()),
        );
        return;
      }
    } catch (e) {
      debugPrint('[DeepLinkService] Error routing link: $e');
    } finally {
      _isHandling = false;
    }
  }

  // ── Helper: Navigate to Product Detail (resolves from memory or network) ──
  Future<void> _navigateToProduct(BuildContext context, String productId) async {
    final productProv = context.read<ProductProvider>();

    // Show temporary floating loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text("Opening product... 🛍️"),
          ],
        ),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final product = await productProv.fetchProductById(productId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (product != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product not found or currently unavailable."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Helper: Navigate to Live Order Tracking ──
  Future<void> _navigateToOrder(BuildContext context, String orderId) async {
    final orderProv = context.read<OrderProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text("Locating your order... 🛵💨"),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final order = await orderProv.fetchOrderDetails(orderId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (order != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(order: order),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order not found or access denied."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Link Generators ──

  static String buildProductLink(String productId) {
    return "https://$webDomain/product/$productId";
  }

  static String buildOrderLink(String orderId) {
    return "https://$webDomain/order/$orderId";
  }

  static String buildCartLink() {
    return "https://$webDomain/cart";
  }

  /// Interactive Product Share Bottom Sheet
  static void showShareProductSheet(BuildContext context, ProductModel product) {
    HapticFeedback.mediumImpact();
    final link = buildProductLink(product.id);
    final variant = product.defaultVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.share_rounded, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Share Product",
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          CustomText(
                            "Friends will open this item directly in app",
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Product Preview Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.images.isNotEmpty ? product.images.first : '',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.shopping_bag, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              product.name,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              "${variant.size} • ₹${variant.price.toStringAsFixed(0)}",
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Link Preview and Copy Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: link));
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Product link copied to clipboard! 📋"),
                              backgroundColor: AppTheme.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text("Copy", style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Direct WhatsApp Share Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final text = "Check out *${product.name}* (${variant.size}) for ₹${variant.price.toStringAsFixed(0)} on UB Mart! ⚡\n$link";
                      final waUri = Uri.parse("whatsapp://send?text=${Uri.encodeComponent(text)}");
                      try {
                        if (await canLaunchUrl(waUri)) {
                          await launchUrl(waUri);
                        } else {
                          final webWa = Uri.parse("https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}");
                          await launchUrl(webWa, mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        debugPrint("Error sharing to WhatsApp: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const CustomText(
                      "Share on WhatsApp",
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}
