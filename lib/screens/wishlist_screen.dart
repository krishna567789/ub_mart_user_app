import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/custom_text.dart';
import 'login_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshFavorites();
    });
  }

  void _refreshFavorites() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isLoggedIn) {
      Provider.of<FavoritesProvider>(
        context,
        listen: false,
      ).loadFavoritesFromBackend();
    }
  }

  void _addAllToCart(List<ProductModel> products) {
    HapticFeedback.mediumImpact();
    final cart = Provider.of<CartProvider>(context, listen: false);
    int addedCount = 0;

    for (final prod in products) {
      if (prod.isAvailable && prod.variants.isNotEmpty) {
        final variant = prod.defaultVariant;
        if (variant.stock > 0) {
          cart.addItem(prod, variant);
          addedCount++;
        }
      }
    }

    if (addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Added $addedCount items to your cart! 🛍️"),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Selected items are currently out of stock."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final favProvider = Provider.of<FavoritesProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Combine favoriteProducts with any matching products from catalog
    final Map<String, ProductModel> productMap = {};
    for (final p in favProvider.favoriteProducts) {
      productMap[p.id] = p;
    }
    for (final p in prodProvider.allProducts) {
      if (favProvider.favoriteIds.contains(p.id) &&
          !productMap.containsKey(p.id)) {
        productMap[p.id] = p;
      }
    }
    final List<ProductModel> wishlistProducts = productMap.values.toList();

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CustomText(
              "My Wishlist",
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
            const SizedBox(width: 8),
            if (wishlistProducts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomText(
                  "${wishlistProducts.length}",
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFF43F5E),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Wishlist",
            icon: Icon(
              Icons.sync_rounded,
              color: favProvider.isLoading
                  ? AppTheme.primary
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _refreshFavorites();
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: !authProvider.isLoggedIn
          ? _buildLoginPrompt(context, isDark)
          : favProvider.isLoading && wishlistProducts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : wishlistProducts.isEmpty
          ? _buildEmptyState(context, isDark)
          : RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => _refreshFavorites(),
              child: CustomScrollView(
                slivers: [
                  // ── Top Summary & Action Bar ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF43F5E,
                                ).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 18,
                                color: Color(0xFFF43F5E),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "${wishlistProducts.length} Saved Items",
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  CustomText(
                                    "Quick reorder anytime with 1 tap",
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey.shade600,
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => _addAllToCart(wishlistProducts),
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 14,
                              ),
                              label: const CustomText(
                                "Add All",
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 2-Column Product Grid ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.50,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = wishlistProducts[index];
                        return ProductCard(product: product);
                      }, childCount: wishlistProducts.length),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 52,
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 20),
            const CustomText(
              "Your Wishlist is Empty",
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 8),
            CustomText(
              "Save your favorite products and essentials by tapping the heart icon on any product card.",
              textAlign: TextAlign.center,
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.storefront_rounded, size: 18),
                label: const CustomText(
                  "Explore Groceries",
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const CustomText(
              "Save Your Favorites",
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
            const SizedBox(height: 8),
            CustomText(
              "Login to save items to your wishlist and access them across all your devices.",
              textAlign: TextAlign.center,
              fontSize: 13,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const CustomText(
                  "Login / Sign Up",
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
