import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../screens/order_tracking_screen.dart';
import '../theme/app_theme.dart';
import 'smart_image.dart';

class DashboardActiveOrderCard extends StatefulWidget {
  final OrderModel order;

  const DashboardActiveOrderCard({
    super.key,
    required this.order,
  });

  @override
  State<DashboardActiveOrderCard> createState() => _DashboardActiveOrderCardState();
}

class _DashboardActiveOrderCardState extends State<DashboardActiveOrderCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scooterController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scooterBobAnimation;
  late AnimationController _arrowController;
  late Animation<double> _arrowSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the live dot
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Subtle scooter bob / bounce animation
    _scooterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scooterBobAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _scooterController, curve: Curves.easeInOut),
    );

    // Arrow slide animation
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _arrowSlideAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scooterController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  int _getStatusStep(String status) {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'ACCEPTED':
        return 1;
      case 'PACKING':
        return 2;
      case 'OUT_FOR_DELIVERY':
        return 3;
      case 'DELIVERED':
        return 4;
      default:
        return 0;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'PENDING':
        return "Order Placed & Received";
      case 'ACCEPTED':
        return "Order Accepted by Store";
      case 'PACKING':
        return "Packing Your Fresh Items";
      case 'OUT_FOR_DELIVERY':
        return "Rider is on the Way!";
      case 'DELIVERED':
        return "Delivered Safely";
      default:
        return "Processing Order";
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status) {
      case 'PENDING':
        return "Store is confirming stock";
      case 'ACCEPTED':
        return "Preparing items for dispatch";
      case 'PACKING':
        return "Hygienically bagged & checked";
      case 'OUT_FOR_DELIVERY':
        return "Heading to your doorstep soon";
      case 'DELIVERED':
        return "Enjoy your fresh purchase!";
      default:
        return "UB Mart Quick Delivery";
    }
  }

  double _getProgressFraction(int step) {
    switch (step) {
      case 0:
        return 0.15;
      case 1:
        return 0.38;
      case 2:
        return 0.65;
      case 3:
        return 0.88;
      case 4:
        return 1.0;
      default:
        return 0.15;
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final int step = _getStatusStep(order.status);
    final double progressFraction = _getProgressFraction(step);

    // Calculate Estimated Delivery Time
    String estimatedTime = "10–15 Mins";
    if (order.createdAt != null) {
      final eta = order.createdAt!.add(const Duration(minutes: 15));
      estimatedTime = DateFormat('hh:mm a').format(eta);
    }

    final displayedItems = order.items.take(3).toList();
    final remainingCount = order.items.length - displayedItems.length;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: step >= 3
                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                : AppTheme.primary.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (step >= 3 ? const Color(0xFF10B981) : AppTheme.primary)
                  .withValues(alpha: 0.22),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Bar: Live Pulse + Order ID + ETA Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Animated Live Pulse Radar Dot
                    _buildPulseLiveIndicator(),
                    const SizedBox(width: 8),
                    const Text(
                      "LIVE ORDER",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.orderId,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // ETA Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: Color(0xFF92400E),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "ETA $estimatedTime",
                            style: const TextStyle(
                              color: Color(0xFF92400E),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Status & Route Track Section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status text and active icon
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusTitle(order.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getStatusSubtitle(order.status),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Mini animated step badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            "Step ${step + 1} of 5",
                            style: TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Animated Delivery Route Progress Line with moving bike
                    _buildAnimatedRouteTrack(progressFraction, step),

                    const SizedBox(height: 14),

                    // Bottom Row: Items preview + Total + Action Button
                    Row(
                      children: [
                        // Overlapping item thumbnails
                        if (displayedItems.isNotEmpty)
                          SizedBox(
                            width: displayedItems.length * 24.0 +
                                (remainingCount > 0 ? 28.0 : 8.0),
                            height: 32,
                            child: Stack(
                              children: [
                                ...List.generate(displayedItems.length, (i) {
                                  final item = displayedItems[i];
                                  return Positioned(
                                    left: i * 22.0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0F172A),
                                          width: 2,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: (item.imageUrl != null &&
                                                item.imageUrl!.isNotEmpty)
                                            ? SmartImage(
                                                imageUrl: item.imageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 16,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),
                                  );
                                }),
                                if (remainingCount > 0)
                                  Positioned(
                                    left: displayedItems.length * 22.0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF334155),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF0F172A),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "+$remainingCount",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        const SizedBox(width: 8),

                        // Order Amount & Items Count
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "₹${order.totalAmount.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                "${order.items.length} item${order.items.length > 1 ? 's' : ''} • ${order.paymentMethod}",
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // "Track Live ➔" Action Button with Animated Arrow
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primary.withValues(alpha: 0.85),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Track Live",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedBuilder(
                                animation: _arrowSlideAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_arrowSlideAnimation.value, 0),
                                    child: child,
                                  );
                                },
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseLiveIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final val = _pulseAnimation.value;
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple
              Container(
                width: 6 + (8 * val),
                height: 6 + (8 * val),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981)
                      .withValues(alpha: (1.0 - val) * 0.6),
                ),
              ),
              // Inner solid dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.8),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedRouteTrack(double progressFraction, int step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double trackWidth = constraints.maxWidth;
        final double scooterX = (trackWidth - 28) * progressFraction;

        return SizedBox(
          height: 34,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Base Track Background
              Positioned(
                left: 12,
                right: 12,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Active Glowing Completed Progress Line
              Positioned(
                left: 12,
                child: Container(
                  width: (trackWidth - 24) * progressFraction,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF38BDF8), Color(0xFF10B981)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),

              // Checkpoint 1: Store (Start)
              Positioned(
                left: 6,
                child: _buildCheckpointNode(
                  icon: Icons.storefront_rounded,
                  isActive: true,
                ),
              ),

              // Checkpoint 2: Packing (Middle-left)
              Positioned(
                left: (trackWidth - 24) * 0.38 + 6,
                child: _buildCheckpointNode(
                  icon: Icons.inventory_2_outlined,
                  isActive: step >= 2,
                ),
              ),

              // Checkpoint 3: Delivery (Middle-right)
              Positioned(
                left: (trackWidth - 24) * 0.68 + 6,
                child: _buildCheckpointNode(
                  icon: Icons.moped_rounded,
                  isActive: step >= 3,
                ),
              ),

              // Checkpoint 4: Home (End)
              Positioned(
                right: 6,
                child: _buildCheckpointNode(
                  icon: Icons.home_rounded,
                  isActive: step >= 4,
                ),
              ),

              // Moving Animated Delivery Scooter Marker
              Positioned(
                left: scooterX.clamp(0.0, trackWidth - 28),
                top: 2,
                child: AnimatedBuilder(
                  animation: _scooterBobAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _scooterBobAnimation.value),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delivery_dining_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckpointNode({
    required IconData icon,
    required bool isActive,
  }) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10B981) : const Color(0xFF1E293B),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? const Color(0xFF6EE7B7)
              : Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 9,
          color: isActive ? Colors.white : Colors.white38,
        ),
      ),
    );
  }
}
