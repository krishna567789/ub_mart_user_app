import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';

class OrderTrackingScreen extends StatelessWidget {
  final OrderModel order;

  const OrderTrackingScreen({super.key, required this.order});

  void _callRider(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine progress index
    final List<String> stages = [
      'PENDING',
      'ACCEPTED',
      'PACKING',
      'OUT_FOR_DELIVERY',
      'DELIVERED',
    ];
    final int currentIndex = stages.indexOf(order.status);
    final bool isCancelled = order.status == 'CANCELLED';

    // Calculate Estimated Delivery Time (Mocking it as 15 mins from created time if not delivered)
    String estimatedTime = "Unknown";
    if (order.createdAt != null &&
        !isCancelled &&
        order.status != 'DELIVERED') {
      final eta = order.createdAt!.add(const Duration(minutes: 15));
      estimatedTime = DateFormat('hh:mm a').format(eta);
    } else if (order.status == 'DELIVERED') {
      estimatedTime = "Delivered";
    } else if (isCancelled) {
      estimatedTime = "Cancelled";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Track Order"),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map / Graphic Section
            Container(
              height: 250,
              width: double.infinity,
              color: AppTheme.primaryLight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Mock map background pattern
                  Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.map, size: 200, color: AppTheme.primary),
                  ),
                  if (!isCancelled && order.status != 'DELIVERED')
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delivery_dining,
                          size: 80,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: Text(
                            "Arriving by $estimatedTime",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (order.status == 'DELIVERED')
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Order Delivered Successfully!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, size: 80, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text(
                          "Order Cancelled",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rider Details
                  if (order.assignedRider != null && !isCancelled) ...[
                    const Text(
                      "Delivery Partner",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blueGrey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.assignedRider!['name'] ?? 'Rider',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  order.assignedRider!['vehicleNumber'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _callRider(order.assignedRider!['phone'] ?? ''),
                            icon: const Icon(Icons.call, color: Colors.green),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade50,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Order Timeline
                  const Text(
                    "Order Status",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (isCancelled)
                    const Text(
                      "This order has been cancelled.",
                      style: TextStyle(color: Colors.red),
                    )
                  else
                    _buildVerticalTimeline(stages, currentIndex),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Order Details
                  const Text(
                    "Order Details",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Order ID: ${order.orderId}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    "Total: ₹${order.totalAmount.toStringAsFixed(0)}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    "Payment: ${order.paymentMethod}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalTimeline(List<String> stages, int currentIndex) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stages.length,
      itemBuilder: (context, index) {
        final isCompleted = index <= currentIndex;
        final isLast = index == stages.length - 1;
        final stageName = stages[index].replaceAll('_', ' ');

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? AppTheme.primary : Colors.grey.shade300,
                  size: 24,
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: isCompleted
                        ? AppTheme.primary
                        : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                stageName[0].toUpperCase() +
                    stageName.substring(1).toLowerCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                  color: isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
