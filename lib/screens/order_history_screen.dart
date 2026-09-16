import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/store_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loaders.dart';
import '../widgets/smart_image.dart';
import 'login_screen.dart';
import 'order_tracking_screen.dart';
import 'cart_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'ALL'; // 'ALL', 'ACTIVE', 'DELIVERED', 'CANCELLED'
  final Set<String> _expandedOrderIds = {};

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
    if (authProvider.isLoggedIn) {
      orderProvider.fetchUserOrders(
        storeId: storeId,
        phone: authProvider.user!.phone,
      );
    }
  }


  String _formatDate(DateTime? dt) {
    if (dt == null) return "Recent Order";
    try {
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0 && now.day == dt.day) {
        return "Today, ${DateFormat('hh:mm a').format(dt)}";
      } else if (diff.inDays <= 1 && now.day - dt.day == 1) {
        return "Yesterday, ${DateFormat('hh:mm a').format(dt)}";
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return "Recent Order";
    }
  }

  void _handleReorder(BuildContext context, OrderModel order) {
    HapticFeedback.mediumImpact();
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
          content: Text("$readded item(s) added to your cart! 🛍️"),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        SnackBar(
          content: const Text("Items from this order are currently out of stock."),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "Rate Your Delivery Experience ⭐",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Order #${order.orderId}",
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Star rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starVal = (index + 1).toDouble();
                      return IconButton(
                        iconSize: 38,
                        icon: Icon(
                          starVal <= currentRating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: textController,
                    maxLines: 3,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Write a short review or delivery feedback (optional)...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                                          ? "Thank you for your rating and feedback! 🎉"
                                          : (orderProv.errorMessage ?? "Failed to submit rating"),
                                    ),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              "Submit Feedback",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Cancel Order?", style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          "Are you sure you want to cancel order #${order.orderId}? If paid online or via wallet, the refund will be credited instantly.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Order", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text("Yes, Cancel"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!authProvider.isLoggedIn) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.w800)),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                  child: Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Track & View Past Orders",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login with your phone number to track active deliveries and view your purchase history.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 220,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text("Login / Sign Up", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allOrders = orderProvider.userOrders;
    final activeOrders = allOrders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();
    final deliveredOrders = allOrders.where((o) => o.status == 'DELIVERED').toList();
    final cancelledOrders = allOrders.where((o) => o.status == 'CANCELLED').toList();

    List<OrderModel> displayedOrders;
    if (_selectedFilter == 'ACTIVE') {
      displayedOrders = activeOrders;
    } else if (_selectedFilter == 'DELIVERED') {
      displayedOrders = deliveredOrders;
    } else if (_selectedFilter == 'CANCELLED') {
      displayedOrders = cancelledOrders;
    } else {
      displayedOrders = allOrders;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        titleSpacing: Navigator.canPop(context) ? 0 : 20,
        title: Row(
          children: [
            const Text(
              "My Orders",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22),
            ),
            const SizedBox(width: 10),
            if (allOrders.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${allOrders.length}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh orders",
            icon: Icon(
              Icons.sync_rounded,
              color: orderProvider.isLoading ? AppTheme.primary : (isDark ? Colors.white70 : Colors.black87),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadOrders();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: orderProvider.isLoading && allOrders.isEmpty
          ? const OrderHistoryShimmer()
          : allOrders.isEmpty
              ? _buildEmptyState(isDark, isOverallEmpty: true)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () async => _loadOrders(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      // ── Filter Pills Strip ──
                      _buildFilterPills(
                        total: allOrders.length,
                        active: activeOrders.length,
                        delivered: deliveredOrders.length,
                        cancelled: cancelledOrders.length,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      if (displayedOrders.isEmpty)
                        _buildEmptyState(isDark, isOverallEmpty: false)
                      else
                        for (final order in displayedOrders) ...[
                          if (order.status != 'DELIVERED' && order.status != 'CANCELLED')
                            _buildActiveOrderHeroCard(order, isDark)
                          else
                            _buildStandardOrderCard(order, isDark),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ),
                ),
    );
  }

  // ── FILTER PILLS STRIP ──
  Widget _buildFilterPills({
    required int total,
    required int active,
    required int delivered,
    required int cancelled,
    required bool isDark,
  }) {
    final filters = [
      {'id': 'ALL', 'label': 'All Orders', 'count': total, 'icon': Icons.all_inbox_rounded},
      {'id': 'ACTIVE', 'label': 'Active 🛵', 'count': active, 'icon': Icons.bolt_rounded},
      {'id': 'DELIVERED', 'label': 'Delivered', 'count': delivered, 'icon': Icons.check_circle_rounded},
      {'id': 'CANCELLED', 'label': 'Cancelled', 'count': cancelled, 'icon': Icons.cancel_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedFilter == f['id'];
          final isFilterActive = f['id'] == 'ACTIVE' && active > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedFilter = f['id'] as String;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : isFilterActive
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : isFilterActive
                            ? const Color(0xFFF97316)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    width: isFilterActive ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFilterActive && !isSelected)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF97316),
                          shape: BoxShape.circle,
                        ),
                      ),
                    Text(
                      "${f['label']} (${f['count']})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : isFilterActive
                                ? const Color(0xFFEA580C)
                                : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── ACTIVE ORDER LIVE TRACKER HERO CARD ──
  Widget _buildActiveOrderHeroCard(OrderModel order, bool isDark) {
    final isOut = order.status == 'OUT_FOR_DELIVERY';
    final isPacking = order.status == 'PACKING';
    final isAccepted = order.status == 'ACCEPTED';
    final isExpanded = _expandedOrderIds.contains(order.id);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFBEB), const Color(0xFFFFF7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOut
              ? const Color(0xFFF97316)
              : const Color(0xFFFBBF24).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Banner Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOut ? const Color(0xFFF97316) : const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isOut ? const Color(0xFFF97316) : const Color(0xFF10B981))
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOut
                          ? "OUT FOR DELIVERY ⚡"
                          : isPacking
                              ? "PACKING & SEALING 📦"
                              : isAccepted
                                  ? "ACCEPTED BY STORE 🏪"
                                  : "ORDER PLACED 🕒",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isOut
                            ? const Color(0xFFEA580C)
                            : isPacking
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    "10-15 Mins",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Order ID & Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${order.orderId}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      _formatDate(order.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "📍 ${order.deliveryAddress.completeAddress}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),

                // Thumbnails preview
                _buildItemThumbnailsRow(order.items, isDark),
                const SizedBox(height: 12),

                // Price and Items Summary
                Row(
                  children: [
                    Text(
                      "₹${order.totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "• ${order.items.length} items • ${order.paymentMethod}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Prominent Gradient Action Button (Track Live Order)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderTrackingScreen(order: order),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
                      label: const Text(
                        "Track Live on Google Map 🛵 →",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isExpanded) {
                        _expandedOrderIds.remove(order.id);
                      } else {
                        _expandedOrderIds.add(order.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.receipt_long_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Expandable Details (Invoice & Instructions)
          if (isExpanded) ...[
            const SizedBox(height: 12),
            _buildExpandedDetails(order, isDark),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── STANDARD DELIVERED / CANCELLED ORDER CARD ──
  Widget _buildStandardOrderCard(OrderModel order, bool isDark) {
    final isDelivered = order.status == 'DELIVERED';
    final isExpanded = _expandedOrderIds.contains(order.id);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header (Status + Date + OrderId)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDelivered
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDelivered ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 13,
                            color: isDelivered ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDelivered ? "DELIVERED" : "CANCELLED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDelivered ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "#${order.orderId}",
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // 2. Middle Row: Product Thumbnails + Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemThumbnailsRow(order.items, isDark),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          "₹${order.totalAmount.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "• ${order.items.length} items • ${order.paymentMethod}",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Rating Pill if available
                    if (order.rating != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              "${order.rating!.toStringAsFixed(1)} ★",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Delivered to ${order.deliveryAddress.tag} • ${order.deliveryAddress.completeAddress}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Action Buttons Row (Reorder + Rating + View Bill)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Reorder in 1-Tap Button
                Expanded(
                  child: SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppTheme.primary.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => _handleReorder(context, order),
                      icon: Icon(Icons.replay_rounded, size: 16, color: AppTheme.primary),
                      label: Text(
                        "Order Again",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Rate Order Button (if not rated)
                if (isDelivered && order.rating == null) ...[
                  SizedBox(
                    height: 38,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.amber.shade700.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () => _showRatingModal(context, order),
                      icon: Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                      label: Text(
                        "Rate",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // View Invoice / Receipt Toggle Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isExpanded) {
                        _expandedOrderIds.remove(order.id);
                      } else {
                        _expandedOrderIds.add(order.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isExpanded ? "Hide" : "Details",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Expanded Receipt Details
          if (isExpanded) _buildExpandedDetails(order, isDark),
        ],
      ),
    );
  }

  // ── ITEM THUMBNAILS ROW ──
  Widget _buildItemThumbnailsRow(List<OrderItemModel> items, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    final displayItems = items.take(4).toList();
    final remainingCount = items.length - displayItems.length;

    return Row(
      children: [
        for (int i = 0; i < displayItems.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: displayItems[i].imageUrl != null && displayItems[i].imageUrl!.isNotEmpty
                    ? SmartImage(
                        imageUrl: displayItems[i].imageUrl!,
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Text("🛍️", style: TextStyle(fontSize: 18)),
                      ),
              ),
            ),
          ),
        if (remainingCount > 0)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: Center(
              child: Text(
                "+$remainingCount",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── EXPANDED RECEIPT & INVOICE BREAKDOWN ──
  Widget _buildExpandedDetails(OrderModel order, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Items Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ITEMS ORDERED (${order.items.length})",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade700,
                ),
              ),
              // Track Order button inside details
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: order)),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.map_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      "View Map Tracking",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Itemized list
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? SmartImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                          : const Center(child: Text("📦", style: TextStyle(fontSize: 14))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${item.quantity}x • ${item.variantSize}",
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${(item.priceAtPurchase * item.quantity).toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, height: 1),
          const SizedBox(height: 10),

          // Delivery Instructions (if any)
          if (order.deliveryInstructions.isNotEmpty) ...[
            Text(
              "DELIVERY INSTRUCTIONS:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: order.deliveryInstructions.map((instruction) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Divider(color: isDark ? Colors.white12 : Colors.grey.shade300, height: 1),
            const SizedBox(height: 10),
          ],

          // Bill Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Item Subtotal",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                "₹${order.itemTotal.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Delivery Fee",
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                order.deliveryFee == 0 ? "FREE" : "₹${order.deliveryFee.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: order.deliveryFee == 0 ? const Color(0xFF10B981) : (isDark ? Colors.white : Colors.black),
                ),
              ),
            ],
          ),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Coupon Discount",
                  style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
                Text(
                  "-₹${order.discountAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Amount Paid",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              Text(
                "₹${order.totalAmount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),

          // Cancel button if PENDING
          if (order.status == 'PENDING') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _confirmCancelOrder(context, order),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text("Cancel Order", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState(bool isDark, {required bool isOverallEmpty}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOverallEmpty ? Icons.shopping_bag_outlined : Icons.filter_alt_off_rounded,
                size: 40,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOverallEmpty ? "No orders placed yet" : "No orders in this filter",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              isOverallEmpty
                  ? "Explore thousands of fresh items and get them delivered in 10-15 minutes!"
                  : "Try selecting a different filter tab above to view your orders.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
