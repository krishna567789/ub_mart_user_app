import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text.dart';
import 'main_navigation_screen.dart';
import 'order_tracking_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppTheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Badge with Concentric Rings
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      ),
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981).withValues(alpha: 0.18),
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF10B981),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                CustomText(
                  "Order Placed Successfully!",
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                const SizedBox(height: 8),

                // Order ID Tag
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: order.orderId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: CustomText("Order ID copied!"),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(
                          "Order ID: #${order.orderId}",
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.copy_rounded, size: 14, color: primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Delivery ETA Guarantee Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 6),
                      CustomText(
                        "Delivery in 10–15 mins guaranteed",
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Order Summary Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            "Total Amount",
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                          CustomText(
                            "₹${order.totalAmount.toStringAsFixed(0)}",
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            "Payment Method",
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomText(
                              order.paymentMethod,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText(
                            "Delivery Handover PIN",
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: CustomText(
                              order.deliveryPin,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Action: Track Order
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderTrackingScreen(order: order),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.delivery_dining_rounded, size: 22),
                    label: const CustomText(
                      "TRACK ORDER LIVE",
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary Action: Continue Shopping
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  child: CustomText(
                    "Continue Shopping",
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
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
