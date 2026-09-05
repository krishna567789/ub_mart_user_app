import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';
import 'login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Cart"),
        actions: [
          if (cart.itemList.isNotEmpty)
            TextButton(
              onPressed: () {
                cart.clearCart();
              },
              child: const Text("Clear Cart", style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.itemList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Your Cart is Empty",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Explore products and add items to your cart",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Start Shopping"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  // Free Delivery Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.primaryLight,
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cart.itemTotal >= 500
                                ? "🎉 You unlocked FREE Delivery!"
                                : "Add ₹${(500 - cart.itemTotal).toStringAsFixed(0)} more for FREE Delivery",
                            style: const TextStyle(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.itemList.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = cart.itemList[index];
                      return Row(
                        children: [
                          // Thumbnail
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: item.product.images.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: item.product.images.first,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.shopping_bag, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),

                          // Name & Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  item.selectedVariant.size,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${item.selectedVariant.price.toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          ),

                          // Quantity Controls
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primary),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    cart.removeItem(item.product.id, item.selectedVariant.size);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.remove, size: 16, color: AppTheme.primary),
                                  ),
                                ),
                                Text(
                                  "${item.quantity}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                InkWell(
                                  onTap: () {
                                    cart.addItem(item.product, item.selectedVariant);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.add, size: 16, color: AppTheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(thickness: 6, color: AppTheme.background),

                  // Coupon Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Coupons & Offers",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        if (cart.appliedCoupon != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Coupon '${cart.appliedCoupon!.code}' Applied",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    Text(
                                      "Saved ₹${cart.discountAmount.toStringAsFixed(0)}",
                                      style: const TextStyle(fontSize: 11, color: Colors.green),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => cart.removeCoupon(),
                                  child: const Text("Remove", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: "Enter Coupon Code",
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final code = _couponController.text.trim().toUpperCase();
                                  if (code.isEmpty) return;

                                  final coupon = cart.availableCoupons.firstWhere(
                                    (c) => c.code.toUpperCase() == code,
                                    orElse: () => throw Exception("Invalid Coupon Code"),
                                  );

                                  if (cart.applyCoupon(coupon)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Coupon $code applied!")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Order total must be at least ₹${coupon.minOrderValue}")),
                                    );
                                  }
                                },
                                child: const Text("APPLY"),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const Divider(thickness: 6, color: AppTheme.background),

                  // Bill Details
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Bill Summary",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Item Total"),
                            Text("₹${cart.itemTotal.toStringAsFixed(0)}"),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Delivery Charge"),
                            Text(
                              cart.deliveryFee == 0 ? "FREE" : "₹${cart.deliveryFee.toStringAsFixed(0)}",
                              style: TextStyle(
                                color: cart.deliveryFee == 0 ? Colors.green : AppTheme.textPrimary,
                                fontWeight: cart.deliveryFee == 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (cart.discountAmount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Coupon Discount"),
                              Text(
                                "-₹${cart.discountAmount.toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "To Pay",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "₹${cart.grandTotal.toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: cart.itemList.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                    child: Text(auth.isLoggedIn ? "PROCEED TO CHECKOUT" : "LOGIN TO CONTINUE"),
                  ),
                ),
              ),
            ),

    );
  }
}
