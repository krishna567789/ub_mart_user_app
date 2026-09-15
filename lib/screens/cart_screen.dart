import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import '../widgets/smart_image.dart';
import '../utils/cart_animation_helper.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplyingCoupon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<StoreProvider>(context, listen: false);
      final storeId = store.selectedStore?.id ?? '';
      if (storeId.isNotEmpty) {
        Provider.of<CartProvider>(context, listen: false).fetchCoupons(storeId);
      }
    });
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
            const Text(
              "Your Cart",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            if (cart.itemCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'}",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryColor),
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
              label: const Text(
                "Clear Cart",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
      body: cart.itemList.isEmpty
          ? _buildEmptyCart(context, primaryColor)
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

                  // 5. Cross-sell / "Missed Anything?" Carousel
                  if (recommendedProducts.isNotEmpty)
                    _buildCrossSellSection(context, recommendedProducts, primaryColor, cart),

                  // 6. Coupons & Offers Section
                  _buildCouponsSection(context, cart, primaryColor),

                  // 7. Delivery Instructions (Door / Bell / Call)
                  _buildDeliveryInstructions(context, cart, primaryColor),

                  // 8. Delivery Partner Tip
                  _buildDeliveryTip(context, cart, primaryColor),

                  // 9. Detailed Bill Summary
                  _buildBillSummary(context, cart, primaryColor),

                  // 10. Cancellation Policy Card
                  _buildCancellationPolicy(),

                  const SizedBox(height: 24),
                ],
              ),
            ),

      // 11. Sticky Checkout Bottom Bar
      bottomNavigationBar: cart.itemList.isEmpty
          ? const SizedBox.shrink()
          : _buildBottomCheckoutBar(context, cart, auth, primaryColor),
    );
  }

  // Empty cart view
  Widget _buildEmptyCart(BuildContext context, Color primaryColor) {
    return Center(
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
              "Looks like you haven't added anything to your cart yet. Explore fresh groceries and daily essentials!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text("Start Shopping", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
                      : "Delivering to your current location",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
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

  // Delivery instructions chips
  Widget _buildDeliveryInstructions(BuildContext context, CartProvider cart, Color primaryColor) {
    final instructions = [
      {"id": "NO_BELL", "label": "Don't ring bell", "icon": "🔕"},
      {"id": "DOOR", "label": "Leave at door", "icon": "🚪"},
      {"id": "NO_CALL", "label": "Avoid calling", "icon": "📞"},
      {"id": "GUARD", "label": "Leave with guard", "icon": "🛡️"},
    ];

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
            "Delivery Instructions",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            "Let the delivery rider know your preferences",
            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
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
                child: Container(
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
                      Text(
                        ins['label']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? primaryColor : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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

  // Cancellation policy card
  Widget _buildCancellationPolicy() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.shield_outlined, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Orders cannot be cancelled once packed for dispatch to ensure ultra-fast 10-minute delivery to your doorstep.",
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  // Sticky bottom action bar
  Widget _buildBottomCheckoutBar(
    BuildContext context,
    CartProvider cart,
    AuthProvider auth,
    Color primaryColor,
  ) {
    final defaultAddress = auth.user?.addresses.isNotEmpty == true ? auth.user!.addresses.first : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left column: Address & Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.home_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        defaultAddress != null ? defaultAddress.tag : "Delivery Address",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "₹${(cart.grandTotal + 2).toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),

            // Right button: Proceed to pay or Login
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                if (!auth.isLoggedIn) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    auth.isLoggedIn ? "PROCEED TO PAY" : "LOGIN TO CONTINUE",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
