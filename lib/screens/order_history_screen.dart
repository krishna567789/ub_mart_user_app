import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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

  Widget _buildOrderTimeline(String status) {
    final List<String> stages = ['PENDING', 'ACCEPTED', 'PACKING', 'OUT_FOR_DELIVERY', 'DELIVERED'];
    final int currentStageIndex = stages.indexOf(status);

    if (status == 'CANCELLED') {
      return Container(
        padding: const EdgeInsets.all(8),
        color: Colors.red.shade50,
        child: const Text("Order Cancelled", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(stages.length, (index) {
          final isCompleted = index <= currentStageIndex;
          final stageName = stages[index]
              .replaceAll('_', ' ')
              .replaceAll('OUT FOR DELIVERY', 'OUT')
              .toLowerCase();

          return Column(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? AppTheme.primary : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                stageName[0].toUpperCase() + stageName.substring(1),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? AppTheme.primary : Colors.grey,
                ),
              ),
            ],
          );
        }),
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
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
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

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.15),
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
                                  color: statusColor.withOpacity(0.15),
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
                          subtitle: Text(
                            "₹${order.totalAmount.toStringAsFixed(0)} • ${order.items.length} items • ${order.paymentMethod}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Live Timeline Progress
                                  _buildOrderTimeline(order.status),
                                  const Divider(),

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
                                          Text("${item.quantity}x ${item.name} (${item.variantSize})"),
                                          Text("₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(0)}"),
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
