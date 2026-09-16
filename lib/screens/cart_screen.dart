import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../providers/favorites_provider.dart';
import '../models/product_model.dart';
import '../widgets/smart_image.dart';
import '../utils/cart_animation_helper.dart';
import 'login_screen.dart';
import 'profile/address_book_screen.dart';
import 'profile/add_address_screen.dart';
import 'order_success_screen.dart';
import 'wishlist_screen.dart';
import 'product_detail_screen.dart';
import 'search/product_search_screen.dart';
import '../models/user_model.dart';
import '../providers/order_provider.dart';
import '../widgets/custom_text.dart';
import '../widgets/slide_to_pay.dart';
import '../config/api_config.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  // Inline Checkout State
  String _paymentMethod = 'COD'; // 'COD', 'ONLINE', 'WALLET'
  AddressModel? _selectedAddress;
  bool _isAddressExpanded = false;
  bool _isPaymentExpanded = false;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<StoreProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeId = store.selectedStore?.id ?? '';
      if (storeId.isNotEmpty) {
        Provider.of<CartProvider>(context, listen: false).fetchCoupons(storeId);
      }
      if (auth.isLoggedIn) {
        Provider.of<FavoritesProvider>(context, listen: false).loadFavoritesFromBackend();
      }
      if (auth.user != null && auth.user!.addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = auth.user!.addresses.first;
        });
      }
    });
  }

  // 1-Tap Add All Wishlisted Items to Cart
  void _addAllWishlistToCart(List<ProductModel> products) {
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
          content: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Added $addedCount items from your wishlist to cart! 🛍️",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Selected wishlist items are currently out of stock."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // Directly Place Order from Cart Screen
  Future<void> _placeOrder() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final store = Provider.of<StoreProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (!auth.isLoggedIn || auth.user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (cart.itemList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your cart is empty")),
      );
      return;
    }

    final double totalToPay = cart.grandTotal + 2;

    // Safety check: Validate wallet balance if paying via WALLET
    if (_paymentMethod == 'WALLET') {
      final currentBalance = auth.user?.walletBalance ?? 0;
      if (currentBalance < totalToPay) {
        final needed = totalToPay - currentBalance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Insufficient Wallet Balance! Available: ₹${currentBalance.toStringAsFixed(0)}, Need: ₹${totalToPay.toStringAsFixed(0)} (Short by ₹${needed.toStringAsFixed(0)}). Please choose COD or Online.",
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
        return;
      }
    }

    AddressModel? addressToUse = _selectedAddress;
    if (addressToUse == null && auth.user!.addresses.isNotEmpty) {
      addressToUse = auth.user!.addresses.first;
    }

    if (addressToUse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select or add a delivery address"),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _isAddressExpanded = true;
      });
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final storeId =
        (store.selectedStore?.id != null && store.selectedStore!.id.isNotEmpty)
            ? store.selectedStore!.id
            : ApiConfig.defaultStoreId;

    final createdOrder = await orderProvider.placeOrder(
      storeId: storeId,
      user: auth.user!,
      deliveryAddress: addressToUse,
      cart: cart,
      paymentMethod: _paymentMethod,
    );

    if (!mounted) return;

    setState(() {
      _isPlacingOrder = false;
    });

    if (createdOrder != null) {
      // Refresh user to update wallet balance
      await auth.refreshUser();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(order: createdOrder),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderProvider.errorMessage ??
                "Failed to place order. Please try again.",
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  // Clear Cart confirmation dialog
  void _confirmClearCart(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Clear Cart?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const Text("Are you sure you want to remove all items from your cart?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  // Bottom sheet to show all available coupons
  void _showAllCouponsModal(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final coupons = cart.availableCoupons;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Available Coupons & Offers",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                "Apply coupons to save more on your groceries",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (coupons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: const [
                      Icon(Icons.discount_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No active coupons at this moment.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: coupons.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final c = coupons[idx];
                      final isEligible = cart.itemTotal >= c.minOrderValue;
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.discount_rounded, color: primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          c.code,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c.discountType == 'FLAT'
                                        ? "Flat ₹${c.discountValue.toStringAsFixed(0)} OFF"
                                        : "${c.discountValue.toStringAsFixed(0)}% OFF up to ₹${c.maxDiscountAmount.toStringAsFixed(0)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    "On orders above ₹${c.minOrderValue.toStringAsFixed(0)}",
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                  if (!isEligible)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        "Add ₹${(c.minOrderValue - cart.itemTotal).toStringAsFixed(0)} more to unlock",
                                        style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: isEligible
                                  ? () async {
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      final store = Provider.of<StoreProvider>(context, listen: false);
                                      final storeId = store.selectedStore?.id ?? '';
                                      final res = await cart.validateAndApplyCouponOnline(
                                        code: c.code,
                                        storeId: storeId,
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message']),
                                          backgroundColor: res['success'] ? Colors.green : Colors.red,
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: const Text("APPLY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final primaryColor = Theme.of(context).primaryColor;
    final products = Provider.of<ProductProvider>(context).products;
    final favProvider = Provider.of<FavoritesProvider>(context);
    final prodProvider = Provider.of<ProductProvider>(context);

    // Map all wishlisted products
    final Map<String, ProductModel> wishlistMap = {};
    for (final p in favProvider.favoriteProducts) {
      wishlistMap[p.id] = p;
    }
    for (final p in prodProvider.allProducts) {
      if (favProvider.favoriteIds.contains(p.id) && !wishlistMap.containsKey(p.id)) {
        wishlistMap[p.id] = p;
      }
    }
    for (final p in prodProvider.products) {
      if (favProvider.favoriteIds.contains(p.id) && !wishlistMap.containsKey(p.id)) {
        wishlistMap[p.id] = p;
      }
    }
    final List<ProductModel> wishlistProducts = wishlistMap.values.toList();

    // Filter cross-sell recommendations (items not currently in cart)
    final inCartIds = cart.itemList.map((i) => i.product.id).toSet();
    final recommendedProducts = products.where((p) => !inCartIds.contains(p.id) && p.defaultVariant.stock > 0).take(6).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CustomText(
              "Your Cart",
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
            if (cart.itemCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomText(
                  "${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}",
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (cart.itemList.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClearCart(context),
              icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
              label: const CustomText(
                "Clear Cart",
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
      body: cart.itemList.isEmpty
          ? _buildEmptyCart(context, primaryColor, wishlistProducts, recommendedProducts, cart, favProvider, auth)
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Delivery ETA & Address Header
                  _buildDeliveryHeader(context, auth, primaryColor),

                  // 2. Free Delivery Progress Banner
                  _buildFreeDeliveryProgress(context, cart, primaryColor),

                  // 3. Savings Celebration Banner
                  if (cart.totalSavings > 0)
                    _buildSavingsBanner(context, cart),

                  // 4. Cart Items Section
                  _buildCartItemsList(context, cart, primaryColor),

                  // 5. From Your Wishlist Section (Production Quick-Add Hub)
                  _buildWishlistSection(context, wishlistProducts, primaryColor, cart, favProvider),

                  // 6. Cross-sell / "Missed Anything?" Carousel
                  if (recommendedProducts.isNotEmpty)
                    _buildCrossSellSection(context, recommendedProducts, primaryColor, cart),

                  // 7. Coupons & Offers Section
                  _buildCouponsSection(context, cart, primaryColor),

                  // 8. Delivery Instructions (Door / Bell / Call)
                  _buildDeliveryInstructions(context, cart, primaryColor),

                  // 9. Delivery Partner Tip
                  _buildDeliveryTip(context, cart, primaryColor),

                  // 10. Detailed Bill Summary
                  _buildBillSummary(context, cart, primaryColor),

                  // 11. Cancellation Policy Card & Trust Guarantees
                  _buildCancellationPolicy(),

                  const SizedBox(height: 24),
                ],
              ),
            ),

      // 12. Sticky Checkout Bottom Bar
      bottomNavigationBar: cart.itemList.isEmpty
          ? const SizedBox.shrink()
          : _buildBottomCheckoutBar(context, cart, auth, primaryColor),
    );
  }

  // Advanced Production Empty Cart view with Wishlist Quick-Order Hub
  Widget _buildEmptyCart(
    BuildContext context,
    Color primaryColor,
    List<ProductModel> wishlistProducts,
    List<ProductModel> recommendedProducts,
    CartProvider cart,
    FavoritesProvider favProvider,
    AuthProvider auth,
  ) {
    if (wishlistProducts.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery ETA header
            _buildDeliveryHeader(context, auth, primaryColor),

            // Empty Cart Banner with Wishlist prompt
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.shopping_bag_outlined, size: 28, color: primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Your Cart is Empty",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "You have ${wishlistProducts.length} items waiting in your wishlist! Add them below to complete your order in 8-10 mins.",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addAllWishlistToCart(wishlistProducts),
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                          label: Text(
                            "Add All (${wishlistProducts.length}) to Cart",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductSearchScreen()),
                          );
                        },
                        icon: const Icon(Icons.search_rounded, size: 16),
                        label: const Text("Search", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Wishlist Products Section Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Your Wishlisted Items",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${wishlistProducts.length}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                    },
                    child: Text(
                      "Manage >",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                ],
              ),
            ),

            // Grid of Wishlist Items
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wishlistProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, idx) {
                  final prod = wishlistProducts[idx];
                  return _buildWishlistGridCard(
                    context,
                    prod,
                    primaryColor,
                    cart,
                    favProvider,
                  );
                },
              ),
            ),

            // Explore More Banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Looking for something else?",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Explore 10,000+ daily essentials and fresh farm groceries.",
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductSearchScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      elevation: 0,
                    ),
                    child: const Text("Explore", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 60),
      child: Column(
        children: [
          _buildDeliveryHeader(context, auth, primaryColor),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.shopping_bag_outlined, size: 64, color: primaryColor),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Your Cart is Empty",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Looks like you haven't added anything to your cart or wishlist yet. Explore fresh groceries and daily essentials!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text("Explore Store", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProductSearchScreen()),
                          );
                        },
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F172A),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (recommendedProducts.isNotEmpty)
            _buildCrossSellSection(context, recommendedProducts, primaryColor, cart),
        ],
      ),
    );
  }

  // Delivery ETA & Location Header
  Widget _buildDeliveryHeader(BuildContext context, AuthProvider auth, Color primaryColor) {
    final defaultAddress = auth.user?.addresses.isNotEmpty == true ? auth.user!.addresses.first : null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () {
                if (auth.user == null) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        "Delivery in 8–10 mins",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    defaultAddress != null
                        ? "${defaultAddress.tag}: ${defaultAddress.completeAddress}"
                        : "Tap to set Google Maps delivery location",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              if (auth.user == null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressBookScreen()));
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    defaultAddress != null ? "CHANGE" : "ADD",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 14, color: primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Free delivery progress bar
  Widget _buildFreeDeliveryProgress(BuildContext context, CartProvider cart, Color primaryColor) {
    final double freeThreshold = 500.0;
    final bool hasFreeDelivery = cart.itemTotal >= freeThreshold;
    final double progress = (cart.itemTotal / freeThreshold).clamp(0.0, 1.0);
    final double remaining = freeThreshold - cart.itemTotal;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFreeDelivery ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFreeDelivery ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFreeDelivery ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                size: 18,
                color: hasFreeDelivery ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasFreeDelivery
                      ? "🎉 Yay! You unlocked FREE Delivery (Saved ₹30)"
                      : "Add ₹${remaining.toStringAsFixed(0)} more for FREE Delivery",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: hasFreeDelivery ? const Color(0xFF047857) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: hasFreeDelivery ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasFreeDelivery ? const Color(0xFF059669) : const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Savings banner
  Widget _buildSavingsBanner(BuildContext context, CartProvider cart) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings_outlined, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            "You are saving ₹${cart.totalSavings.toStringAsFixed(0)} on this order!",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // Cart items list with advanced quantity stepper
  Widget _buildCartItemsList(BuildContext context, CartProvider cart, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Review Items",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                Text(
                  "${cart.itemList.length} items",
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cart.itemList.length,
            separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final item = cart.itemList[index];
              final variant = item.selectedVariant;
              final double origPrice = variant.originalPrice ?? variant.price;
              final bool hasDiscount = origPrice > variant.price;
              final double savings = (origPrice - variant.price) * item.quantity;

              return Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 58,
                        height: 58,
                        color: const Color(0xFFF8FAFC),
                        child: SmartImage(
                          imageUrl: item.product.images.isNotEmpty ? item.product.images.first : '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Variant
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            variant.size,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "₹${variant.price.toStringAsFixed(0)}",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 6),
                                Text(
                                  "₹${origPrice.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (savings > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "Save ₹${savings.toStringAsFixed(0)}",
                                      style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Advanced Quantity Stepper
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              cart.removeItem(item.product.id, variant.size);
                            },
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Icon(
                                item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
                                size: 16,
                                color: item.quantity == 1 ? Colors.red : primaryColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              "${item.quantity}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              cart.addItem(item.product, variant);
                            },
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Icon(Icons.add, size: 16, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 5. Wishlist Section ("From Your Wishlist ❤️") ──
  Widget _buildWishlistSection(
    BuildContext context,
    List<ProductModel> wishlistProducts,
    Color primaryColor,
    CartProvider cart,
    FavoritesProvider favProvider,
  ) {
    if (wishlistProducts.isEmpty) {
      // Sleek discovery card for saving items
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF1F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_outline_rounded, color: Color(0xFFF43F5E), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Save items with ❤️ for 1-tap reordering",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Tap the heart on any product to quickly access & order your favorites here.",
                    style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CustomText(
                            "From Your Wishlist",
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: CustomText(
                              "${wishlistProducts.length}",
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      const CustomText(
                        "Items you saved • Add directly to this order",
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          "View All",
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.arrow_forward_ios_rounded, size: 10, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Wishlist Carousel
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: wishlistProducts.length,
              itemBuilder: (context, idx) {
                final prod = wishlistProducts[idx];
                return _buildWishlistProductCard(
                  context,
                  prod,
                  primaryColor,
                  cart,
                  favProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistProductCard(
    BuildContext context,
    ProductModel prod,
    Color primaryColor,
    CartProvider cart,
    FavoritesProvider favProvider,
  ) {
    final v = prod.defaultVariant;
    final imgKey = GlobalKey();
    final double origPrice = v.originalPrice ?? v.price;
    final bool hasDiscount = origPrice > v.price;
    final int discountPercent = hasDiscount && origPrice > 0
        ? (((origPrice - v.price) / origPrice) * 100).round()
        : 0;

    int inCartQty = 0;
    for (final item in cart.itemList) {
      if (item.product.id == prod.id && item.selectedVariant.size == v.size) {
        inCartQty = item.quantity;
        break;
      }
    }

    return Container(
      width: 135,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Discount tag & Heart icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasDiscount && discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomText(
                    "$discountPercent% OFF",
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFEF4444),
                  ),
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  favProvider.toggleFavorite(prod.id, prod);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    favProvider.isFavorite(prod.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 16,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Image
          Center(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  key: imgKey,
                  width: 58,
                  height: 58,
                  child: SmartImage(
                    imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Product Name
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
              );
            },
            child: CustomText(
              prod.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          CustomText(
            v.size,
            fontSize: 9.5,
            color: const Color(0xFF64748B),
          ),
          const Spacer(),

          // Price & Add / Stepper Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "₹${v.price.toStringAsFixed(0)}",
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  if (hasDiscount)
                    CustomText(
                      "₹${origPrice.toStringAsFixed(0)}",
                      fontSize: 9,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                ],
              ),
              if (inCartQty == 0)
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    CartAnimationHelper.flyToCart(
                      context: context,
                      imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                      sourceKey: imgKey,
                    );
                    cart.addItem(prod, v);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: Colors.white),
                        SizedBox(width: 2),
                        CustomText(
                          "ADD",
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.removeItem(prod.id, v.size);
                        },
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: Icon(
                            inCartQty == 1 ? Icons.delete_outline_rounded : Icons.remove,
                            size: 13,
                            color: inCartQty == 1 ? Colors.red : primaryColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CustomText(
                          "$inCartQty",
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.addItem(prod, v);
                        },
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          child: Icon(Icons.add, size: 13, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistGridCard(
    BuildContext context,
    ProductModel prod,
    Color primaryColor,
    CartProvider cart,
    FavoritesProvider favProvider,
  ) {
    final v = prod.defaultVariant;
    final imgKey = GlobalKey();
    final double origPrice = v.originalPrice ?? v.price;
    final bool hasDiscount = origPrice > v.price;
    final int discountPercent = hasDiscount && origPrice > 0
        ? (((origPrice - v.price) / origPrice) * 100).round()
        : 0;

    int inCartQty = 0;
    for (final item in cart.itemList) {
      if (item.product.id == prod.id && item.selectedVariant.size == v.size) {
        inCartQty = item.quantity;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (hasDiscount && discountPercent > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "$discountPercent% OFF",
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                  ),
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  favProvider.toggleFavorite(prod.id, prod);
                },
                child: Icon(
                  favProvider.isFavorite(prod.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 18,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Image
          Center(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  key: imgKey,
                  width: 75,
                  height: 75,
                  child: SmartImage(
                    imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Name & Variant
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)),
              );
            },
            child: Text(
              prod.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), height: 1.2),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            v.size,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
          const Spacer(),

          // Bottom Price & ADD / Stepper
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${v.price.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  if (hasDiscount)
                    Text(
                      "₹${origPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              if (inCartQty == 0)
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    cart.addItem(prod, v);
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text("ADD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                )
              else
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.removeItem(prod.id, v.size);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(
                            inCartQty == 1 ? Icons.delete_outline_rounded : Icons.remove,
                            size: 14,
                            color: inCartQty == 1 ? Colors.red : primaryColor,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "$inCartQty",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          cart.addItem(prod, v);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(Icons.add, size: 14, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Cross-sell recommendations carousel ("Missed anything?")
  Widget _buildCrossSellSection(
    BuildContext context,
    List<ProductModel> products,
    Color primaryColor,
    CartProvider cart,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 14),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.add_shopping_cart_rounded, size: 16, color: Color(0xFFEA580C)),
                SizedBox(width: 6),
                Text(
                  "Before You Checkout",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 10),
            child: Text(
              "Frequently bought items you might like to add",
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, idx) {
                final prod = products[idx];
                final v = prod.defaultVariant;
                final key = GlobalKey();

                return Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            key: key,
                            width: 50,
                            height: 50,
                            child: SmartImage(
                              imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        v.size,
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${v.price.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              CartAnimationHelper.flyToCart(
                                context: context,
                                imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                                sourceKey: key,
                              );
                              cart.addItem(prod, v);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "ADD",
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Coupons Section
  Widget _buildCouponsSection(BuildContext context, CartProvider cart, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 18, color: Color(0xFF0F172A)),
                  SizedBox(width: 8),
                  Text(
                    "Coupons & Offers",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showAllCouponsModal(context),
                child: Text(
                  "View All >",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (cart.appliedCoupon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "'${cart.appliedCoupon!.code}' Applied",
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF15803D), fontSize: 13),
                          ),
                          Text(
                            "You saved ₹${cart.discountAmount.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      cart.removeCoupon();
                      HapticFeedback.lightImpact();
                    },
                    child: const Text("Remove", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "Enter Promo Code",
                      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isApplyingCoupon
                        ? null
                        : () async {
                            final code = _couponController.text.trim();
                            if (code.isEmpty) return;

                            setState(() => _isApplyingCoupon = true);
                            final store = Provider.of<StoreProvider>(context, listen: false);
                            final storeId = store.selectedStore?.id ?? '';
                            final result = await cart.validateAndApplyCouponOnline(
                              code: code,
                              storeId: storeId,
                            );
                            setState(() => _isApplyingCoupon = false);

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success'] ? Colors.green : Colors.red,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: _isApplyingCoupon
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),

            // Top coupon quick suggestions
            if (cart.availableCoupons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: cart.availableCoupons.take(2).map((c) {
                  return GestureDetector(
                    onTap: () {
                      _couponController.text = c.code;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sell_outlined, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            "${c.code} • Tap to apply",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // Delivery instructions chips & custom rider notes (Zepto / Blinkit standard)
  Widget _buildDeliveryInstructions(BuildContext context, CartProvider cart, Color primaryColor) {
    final instructions = [
      {"id": "NO_BELL", "label": "Don't ring bell", "icon": "🔕"},
      {"id": "DOOR", "label": "Leave at door", "icon": "🚪"},
      {"id": "NO_CALL", "label": "Avoid calling", "icon": "📞"},
      {"id": "GUARD", "label": "Leave with guard", "icon": "🛡️"},
      {"id": "PET", "label": "Pet at home", "icon": "🐕"},
      {"id": "BABY", "label": "Baby sleeping", "icon": "👶"},
    ];

    final hasNote = cart.deliveryNote.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_bike_rounded, size: 16, color: primaryColor),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      "Delivery Instructions",
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                    SizedBox(height: 2),
                    CustomText(
                      "Select preferences for your delivery partner",
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 1-Tap Quick Action Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: instructions.map((ins) {
              final isSelected = cart.deliveryInstructions.contains(ins['id']);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  cart.toggleDeliveryInstruction(ins['id']!);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor.withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(ins['icon']!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      CustomText(
                        ins['label']!,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? primaryColor : const Color(0xFF334155),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 5),
                        Icon(Icons.check_circle_rounded, size: 14, color: primaryColor),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Custom Delivery Note input tile
          if (!hasNote)
            GestureDetector(
              onTap: () => _showDeliveryNoteSheet(context, cart, primaryColor),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20, color: primaryColor),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: CustomText(
                        "Add directions / landmark note for rider",
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withValues(alpha: 0.28)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes_rounded, size: 18, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDeliveryNoteSheet(context, cart, primaryColor),
                      child: CustomText(
                        "Note: \"${cart.deliveryNote}\"",
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cart.setDeliveryNote('');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDeliveryNoteSheet(BuildContext context, CartProvider cart, Color primaryColor) {
    final controller = TextEditingController(text: cart.deliveryNote);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    "Delivery Note for Rider",
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const CustomText(
                "Add landmark or specific directions to help your rider locate you faster",
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLength: 120,
                maxLines: 3,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: "e.g. 2nd floor, flat 204, red gate near neem tree...",
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primaryColor, width: 1.8),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  "Gate code: ",
                  "Lift on right",
                  "Call on arrival",
                  "Leave with neighbor",
                ].map((sug) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.text =
                          controller.text.isEmpty ? sug : "${controller.text}, $sug";
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        "+ $sug",
                        fontSize: 11,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    cart.setDeliveryNote(controller.text.trim());
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const CustomText(
                    "Save Instruction",
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Delivery Partner Tip
  Widget _buildDeliveryTip(BuildContext context, CartProvider cart, Color primaryColor) {
    final tipOptions = [10.0, 20.0, 30.0, 50.0];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.two_wheeler_rounded, size: 18, color: Color(0xFF0F172A)),
              SizedBox(width: 8),
              Text(
                "Tip Your Delivery Partner",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "100% of this tip goes directly to your rider",
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...tipOptions.map((tip) {
                final isSelected = cart.deliveryTip == tip;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      cart.setDeliveryTip(isSelected ? 0.0 : tip);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        "₹${tip.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (cart.deliveryTip > 0)
                GestureDetector(
                  onTap: () => cart.setDeliveryTip(0.0),
                  child: const Text(
                    "Clear",
                    style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Bill Summary
  Widget _buildBillSummary(BuildContext context, CartProvider cart, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bill Summary",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          _buildBillRow("Item Total (MRP)", "₹${cart.totalMrp.toStringAsFixed(0)}"),
          if (cart.totalSavings > 0)
            _buildBillRow(
              "Product Discount",
              "-₹${(cart.totalMrp - cart.itemTotal).toStringAsFixed(0)}",
              color: const Color(0xFF16A34A),
            ),
          _buildBillRow(
            "Delivery Partner Fee",
            cart.deliveryFee == 0 ? "FREE" : "₹${cart.deliveryFee.toStringAsFixed(0)}",
            strikethrough: cart.deliveryFee == 0 ? "₹30" : null,
            color: cart.deliveryFee == 0 ? const Color(0xFF16A34A) : null,
          ),
          _buildBillRow("Handling & Bag Charge", "₹2", strikethrough: "₹5", color: const Color(0xFF16A34A)),
          if (cart.deliveryTip > 0)
            _buildBillRow("Rider Tip", "₹${cart.deliveryTip.toStringAsFixed(0)}"),
          if (cart.discountAmount > 0)
            _buildBillRow("Coupon Discount", "-₹${cart.discountAmount.toStringAsFixed(0)}", color: const Color(0xFF16A34A)),

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "To Pay",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  if (cart.totalSavings > 0)
                    Text(
                      "Saved ₹${cart.totalSavings.toStringAsFixed(0)} on this order",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w700),
                    ),
                ],
              ),
              Text(
                "₹${(cart.grandTotal + 2).toStringAsFixed(0)}", // include handling fee
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, {String? strikethrough, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              if (strikethrough != null) ...[
                Text(
                  strikethrough,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color ?? const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Cancellation policy & Quality Guarantee card (Blinkit / Zepto style)
  Widget _buildCancellationPolicy() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Badges Row
          Row(
            children: [
              _buildTrustBadge(Icons.bolt_rounded, const Color(0xFF10B981), "10-Min Fast", "Express Delivery"),
              const SizedBox(width: 8),
              _buildTrustBadge(Icons.verified_rounded, const Color(0xFF3B82F6), "100% Genuine", "Quality Checked"),
              const SizedBox(width: 8),
              _buildTrustBadge(Icons.assignment_return_rounded, const Color(0xFF8B5CF6), "Easy Refund", "No Questions"),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Cancellation Policy: Orders cannot be cancelled once packed for dispatch to ensure ultra-fast 10-minute delivery to your doorstep.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, Color color, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: color),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // Sticky bottom action bar with inline expandable address manager & payment method selector
  Widget _buildBottomCheckoutBar(
    BuildContext context,
    CartProvider cart,
    AuthProvider auth,
    Color primaryColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final addresses = auth.user?.addresses ?? [];
    final activeAddress = _selectedAddress ?? (addresses.isNotEmpty ? addresses.first : null);
    final double totalPayable = cart.grandTotal + 2;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. EXPANDABLE ADDRESS SELECTOR / CARD ──
            _buildAddressSection(context, auth, activeAddress, addresses, primaryColor, isDark),

            // Divider between address and payment
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),

            // ── 2. PAYMENT METHOD SELECTOR ──
            _buildPaymentMethodSection(auth, primaryColor, isDark),

            // Divider before action row
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),

            // ── 3. BOTTOM CHECKOUT ROW WITH INTERACTIVE SLIDE-TO-PAY ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Address & Payment Mode Summary Strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            activeAddress?.tag == 'WORK'
                                ? Icons.work_outline_rounded
                                : activeAddress?.tag == 'HOME'
                                    ? Icons.home_outlined
                                    : Icons.place_outlined,
                            size: 14,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          CustomText(
                            "Delivering to: ${activeAddress != null ? activeAddress.tag : 'Selected Address'}",
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF64748B),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _paymentMethod == 'COD'
                                  ? Icons.local_shipping_outlined
                                  : _paymentMethod == 'WALLET'
                                      ? Icons.account_balance_wallet_outlined
                                      : Icons.credit_card_outlined,
                              size: 12,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 4),
                            CustomText(
                              _paymentMethod == 'COD'
                                  ? "Cash on Delivery"
                                  : _paymentMethod == 'WALLET'
                                      ? "UB Wallet"
                                      : "Online / UPI",
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Slide To Pay Interactive Slider
                  SlideToPay(
                    totalAmount: totalPayable,
                    paymentMethod: _paymentMethod,
                    isLoading: _isPlacingOrder,
                    enabled: cart.itemList.isNotEmpty,
                    primaryColor: primaryColor,
                    customLabel: !auth.isLoggedIn
                        ? "SLIDE TO LOGIN & ORDER ❯❯❯"
                        : _paymentMethod == 'COD'
                            ? "SLIDE TO PLACE COD ORDER ❯❯❯"
                            : _paymentMethod == 'WALLET'
                                ? "SLIDE TO PAY VIA WALLET ❯❯❯"
                                : "SLIDE TO PAY ₹${totalPayable.toStringAsFixed(0)} ❯❯❯",
                    onDisabledTap: () {
                      if (!auth.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                        return;
                      }
                      if (activeAddress == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: CustomText(
                              "Please select or add a delivery address",
                              color: Colors.white,
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        setState(() => _isAddressExpanded = true);
                        return;
                      }
                    },
                    onSlideComplete: () {
                      HapticFeedback.heavyImpact();
                      _placeOrder();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Address Section with Expandable View & Google Map Add Button
  Widget _buildAddressSection(
    BuildContext context,
    AuthProvider auth,
    AddressModel? activeAddress,
    List<AddressModel> addresses,
    Color primaryColor,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsed Header Strip (Always Visible)
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isAddressExpanded = !_isAddressExpanded;
              if (_isAddressExpanded) _isPaymentExpanded = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Location Icon
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    activeAddress?.tag == 'WORK'
                        ? Icons.work_rounded
                        : activeAddress?.tag == 'HOME'
                            ? Icons.home_rounded
                            : Icons.location_on_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Address summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Delivering to: ",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              activeAddress != null ? activeAddress.tag : "NO ADDRESS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          if (activeAddress != null && activeAddress.lat != null) ...[
                            const SizedBox(width: 4),
                            const Text("📍", style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activeAddress != null
                            ? activeAddress.completeAddress
                            : "Tap here to add or choose delivery address",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand / Collapse Chevron Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isAddressExpanded ? "CLOSE" : "CHANGE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isAddressExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded Address List & Add Button
        if (_isAddressExpanded)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Delivery Address",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      "${addresses.length} Saved",
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // List of saved addresses
                if (addresses.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      itemCount: addresses.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 6),
                      itemBuilder: (ctx, index) {
                        final addr = addresses[index];
                        final isSelected = activeAddress?.id == addr.id ||
                            activeAddress?.completeAddress == addr.completeAddress;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedAddress = addr;
                              _isAddressExpanded = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: isSelected ? primaryColor : Colors.grey.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              addr.tag,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            addr.receiverName,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        addr.completeAddress,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No addresses saved yet. Add your address with Google Map below.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),

                const SizedBox(height: 10),

                // Button: Add New Address with Google Map
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddAddressScreen()),
                      );
                      if (!context.mounted) return;
                      final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
                      if (updatedAuth.user != null && updatedAuth.user!.addresses.isNotEmpty) {
                        setState(() {
                          _selectedAddress = updatedAuth.user!.addresses.first;
                          _isAddressExpanded = false;
                        });
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text(
                      "+ Add New Address with Google Map",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Payment Method Section (Expandable with Active Preview & Inline Selection)
  Widget _buildPaymentMethodSection(
    AuthProvider auth,
    Color primaryColor,
    bool isDark,
  ) {
    final walletBalance = auth.user?.walletBalance ?? 0;

    String paymentTag = "CASH (COD)";
    String paymentSubtitle = "Pay via cash or UPI QR at doorstep";
    IconData paymentIcon = Icons.payments_rounded;

    if (_paymentMethod == 'ONLINE') {
      paymentTag = "UPI / ONLINE";
      paymentSubtitle = "Instant GPay, PhonePe, Cards, NetBanking";
      paymentIcon = Icons.bolt_rounded;
    } else if (_paymentMethod == 'WALLET') {
      paymentTag = "UB WALLET";
      paymentSubtitle = "Available Balance: ₹${walletBalance.toStringAsFixed(0)}";
      paymentIcon = Icons.account_balance_wallet_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Collapsed Header Strip (Always Visible, Matching Address Strip)
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _isPaymentExpanded = !_isPaymentExpanded;
              if (_isPaymentExpanded) _isAddressExpanded = false;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                // Payment Icon in circular badge
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    paymentIcon,
                    size: 16,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 10),

                // Payment summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            "Paying with: ",
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              paymentTag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.shield_outlined, size: 12, color: Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        paymentSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Expand / Collapse Chevron Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isPaymentExpanded ? "CLOSE" : "CHANGE",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _isPaymentExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded Payment Methods List (Smooth & Expandable)
        if (_isPaymentExpanded)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Select Payment Option",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          "100% SECURE & ENCRYPTED",
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 1. Cash on Delivery
                _buildPaymentExpandItem(
                  id: 'COD',
                  title: 'Cash on Delivery (COD)',
                  subtitle: 'Pay via cash or UPI QR scan at doorstep',
                  tag: 'POPULAR',
                  icon: Icons.payments_rounded,
                  isSelected: _paymentMethod == 'COD',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _paymentMethod = 'COD';
                      _isPaymentExpanded = false;
                    });
                  },
                ),
                const SizedBox(height: 6),

                // 2. UPI / Online Payment
                _buildPaymentExpandItem(
                  id: 'ONLINE',
                  title: 'UPI / Online Payment',
                  subtitle: 'GPay, PhonePe, Paytm, Cards & NetBanking',
                  tag: 'FASTEST',
                  icon: Icons.bolt_rounded,
                  isSelected: _paymentMethod == 'ONLINE',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _paymentMethod = 'ONLINE';
                      _isPaymentExpanded = false;
                    });
                  },
                ),
                const SizedBox(height: 6),

                // 3. UB Wallet
                _buildPaymentExpandItem(
                  id: 'WALLET',
                  title: 'UB Mart Wallet',
                  subtitle: 'Instant 1-tap checkout from wallet balance',
                  tag: '₹${walletBalance.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: _paymentMethod == 'WALLET',
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _paymentMethod = 'WALLET';
                      _isPaymentExpanded = false;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentExpandItem({
    required String id,
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? primaryColor : Colors.grey.shade400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isSelected ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: primaryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
