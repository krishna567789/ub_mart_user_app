import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../utils/cart_animation_helper.dart';
import '../widgets/custom_text.dart';
import 'home/home_screen.dart';
import 'categories_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _cartBounceController;
  late Animation<double> _cartBounceAnimation;

  final List<Widget> _pages = const [
    HomeScreen(),
    CategoriesScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex > 3 ? 3 : widget.initialIndex;

    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _cartBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 0.97).chain(CurveTween(curve: Curves.easeInOut)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.97, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_cartBounceController);

    CartAnimationHelper.cartBounceNotifier.addListener(_onCartBounceTrigger);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // First load saved user to restore auth token
      await auth.loadSavedUser();
      if (!mounted) return;
      if (auth.isLoggedIn) {
        Provider.of<CartProvider>(context, listen: false).loadCartFromBackend();
        Provider.of<FavoritesProvider>(context, listen: false).loadFavoritesFromBackend();
        if (auth.user != null) {
          Provider.of<OrderProvider>(context, listen: false).fetchUserOrders(
            storeId: '',
            phone: auth.user!.phone,
          );
        }
      }
    });
  }

  void _onCartBounceTrigger() {
    if (mounted) _cartBounceController.forward(from: 0.0);
  }

  @override
  void dispose() {
    CartAnimationHelper.cartBounceNotifier.removeListener(_onCartBounceTrigger);
    _cartBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Show floating cart on all screens except Cart screen (index 2)
    final showFloatingCart = cart.itemCount > 0 && _currentIndex != 2;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // Global Floating Cart Bar — pinned just above the bottom nav
          if (showFloatingCart)
            Positioned(
              left: 0,
              right: 0,
              bottom: 6,
              child: _buildGlobalCartBar(context, cart, primaryColor),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF13151A),
          border: Border(
            top: BorderSide(
              color: isLight ? Colors.grey.shade200 : Colors.white10,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isLight ? 0.05 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: primaryColor,
          unselectedItemColor: isLight ? Colors.grey.shade600 : Colors.grey.shade500,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: "Categories",
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${cart.itemCount}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.shopping_bag),
              label: "Cart",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "Account",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalCartBar(BuildContext context, CartProvider cart, Color primaryColor) {
    final displayedItems = cart.itemList.take(3).toList();
    final totalSavings = cart.totalSavings;

    return IntrinsicHeight(
      child: ScaleTransition(
        scale: _cartBounceAnimation,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _currentIndex = 2); // Navigate to Cart tab
          },
        child: Container(
          // No GlobalKey here to avoid conflict with cart animation target
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withValues(alpha: 0.35), width: 1.2),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 4)),
              BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top delivery bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.5), blurRadius: 5)],
                          ),
                        ),
                        const SizedBox(width: 7),
                        const CustomText(
                          "Locked: 8–10 Min Guaranteed Delivery",
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    if (totalSavings > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 10, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 3),
                            CustomText(
                              "Saved ₹${totalSavings.toStringAsFixed(0)}",
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF92400E),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Bottom cart info row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Row(
                  children: [
                    // Product image thumbnails (circular)
                    SizedBox(
                      width: displayedItems.length * 28.0 + 4,
                      height: 38,
                      child: Stack(
                        children: List.generate(displayedItems.length, (i) {
                          final item = displayedItems[i];
                          return Positioned(
                            left: i * 28.0,
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                ],
                              ),
                              child: ClipOval(
                                child: item.product.images.isNotEmpty
                                    ? Image.network(item.product.images.first, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 18, color: Colors.grey))
                                    : const Icon(Icons.shopping_bag, size: 18, color: Colors.grey),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Price & item count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomText(
                                "₹${cart.grandTotal.toStringAsFixed(0)}",
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                              if (cart.totalMrp > cart.itemTotal) ...[
                                const SizedBox(width: 6),
                                CustomText(
                                  "₹${cart.totalMrp.toStringAsFixed(0)}",
                                  color: Colors.white38,
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.white38,
                                ),
                              ],
                            ],
                          ),
                          CustomText(
                            "${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''} • Ready",
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                    // View Cart button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomText("View Cart", color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}


