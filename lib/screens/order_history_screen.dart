import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loaders.dart';
import 'login_screen.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  void _loadOrders() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final storeId = storeProvider.selectedStore?.id ?? '';
    if (authProvider.isLoggedIn && storeId.isNotEmpty) {
      orderProvider.fetchUserOrders(
        storeId: storeId,
        phone: authProvider.user!.phone,
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
      case 'PACKING':
        return Colors.orange;
      case 'OUT_FOR_DELIVERY':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return AppTheme.accent;
    }
  }

  void _handleReorder(BuildContext context, OrderModel order) {
    final cartProv = Provider.of<CartProvider>(context, listen: false);
    final prodProv = Provider.of<ProductProvider>(context, listen: false);
    final orderProv = Provider.of<OrderProvider>(context, listen: false);

    final readded = orderProv.reorder(
      pastOrder: order,
      cart: cartProv,
      catalogProducts: prodProv.allProducts,
    );

    if (readded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$readded item(s) added to your cart!"),
          backgroundColor: AppTheme.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: "VIEW CART",
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Items from this order are currently out of stock."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showRatingModal(BuildContext context, OrderModel order) {
    double currentRating = order.rating ?? 5.0;
    final textController = TextEditingController(text: order.review ?? '');
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Rate Your Delivery",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Order #${order.orderId}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  // Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = (index + 1).toDouble();
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starVal <= currentRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setModalState(() {
                            currentRating = starVal;
                          });
                        },
                      );
                    }),
                  ),
                  Text(
                    currentRating == 5
                        ? "Excellent! ⭐⭐⭐⭐⭐"
                        : currentRating == 4
                            ? "Very Good! ⭐⭐⭐⭐"
                            : currentRating == 3
                                ? "Good ⭐⭐⭐"
                                : currentRating == 2
                                    ? "Could be better ⭐⭐"
                                    : "Poor experience ⭐",
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Write a short review or feedback (optional)...",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              final orderProv = Provider.of<OrderProvider>(context, listen: false);
                              final success = await orderProv.rateOrder(
                                orderId: order.id,
                                rating: currentRating,
                                review: textController.text.trim(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? "Thank you for your rating and feedback!"
                                          : (orderProv.errorMessage ?? "Failed to submit rating"),
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Submit Rating",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmCancelOrder(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: Text(
          "Are you sure you want to cancel order #${order.orderId}? If paid using wallet, the refund will be credited instantly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Order"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final storeProv = Provider.of<StoreProvider>(context, listen: false);
              final orderProv = Provider.of<OrderProvider>(context, listen: false);
              final ok = await orderProv.cancelOrder(
                orderId: order.id,
                storeId: storeProv.selectedStore?.id ?? '',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? "Order cancelled successfully."
                          : (orderProv.errorMessage ?? "Could not cancel order"),
                    ),
                    backgroundColor: ok ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Orders")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Please login to view your order history",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("Login / Sign Up"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: orderProvider.isLoading && orderProvider.userOrders.isEmpty
          ? const OrderHistoryShimmer()
          : orderProvider.userOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 70, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        "No orders placed yet",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _loadOrders(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orderProvider.userOrders.length,
                    itemBuilder: (context, index) {
                      final order = orderProvider.userOrders[index];
                      final statusColor = _getStatusColor(order.status);
                      final isDelivered = order.status == 'DELIVERED';
                      final isCancelled = order.status == 'CANCELLED';
                      final isPending = order.status == 'PENDING';

                      return Card(
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.15),
                            child: Icon(Icons.shopping_bag, color: statusColor),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderId,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "₹${order.totalAmount.toStringAsFixed(0)} • ${order.items.length} items • ${order.paymentMethod}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (order.rating != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      "${order.rating!.toStringAsFixed(1)} ★",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    if (order.review != null && order.review!.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          "\"${order.review}\"",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Action Buttons (Track / Re-order / Rate / Cancel)
                                  Row(
                                    children: [
                                      if (!isDelivered && !isCancelled) ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => OrderTrackingScreen(order: order),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.location_on, size: 16),
                                            label: const Text("Track Order"),
                                          ),
                                        ),
                                      ],
                                      if (isDelivered || isCancelled) ...[
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () => _handleReorder(context, order),
                                            icon: const Icon(Icons.replay_rounded, size: 16),
                                            label: const Text("Order Again"),
                                          ),
                                        ),
                                      ],
                                      if (isDelivered) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber.shade700,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            onPressed: () => _showRatingModal(context, order),
                                            icon: const Icon(Icons.star, size: 16),
                                            label: Text(order.rating == null ? "Rate Order" : "Edit Rating"),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  if (isPending) ...[
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: double.infinity,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                        ),
                                        onPressed: () => _confirmCancelOrder(context, order),
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text("Cancel Order"),
                                      ),
                                    ),
                                  ],

                                  const Divider(),

                                  // Delivery Instructions (if any)
                                  if (order.deliveryInstructions.isNotEmpty) ...[
                                    const Text(
                                      "Delivery Instructions:",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: order.deliveryInstructions.map((instruction) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle_outline, size: 12, color: Colors.blue),
                                              const SizedBox(width: 4),
                                              Text(
                                                instruction,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.blue,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 8),
                                    const Divider(),
                                  ],

                                  // Items Ordered
                                  const Text(
                                    "Items Ordered:",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  for (var item in order.items)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "${item.quantity}x ${item.name} (${item.variantSize})",
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          Text(
                                            "₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(0)}",
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Delivery Address:"),
                                      Text(
                                        order.deliveryAddress.tag,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    order.deliveryAddress.completeAddress,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
