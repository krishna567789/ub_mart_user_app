import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../providers/store_provider.dart';
import '../providers/order_provider.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'location_select_screen.dart';
import 'profile/address_book_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';
import 'wishlist_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final store = Provider.of<StoreProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        Provider.of<FavoritesProvider>(context, listen: false).loadFavoritesFromBackend();
        final phone = auth.user?.phone ?? '';
        final storeId = store.selectedStore?.id ?? '';
        if (phone.isNotEmpty) {
          Provider.of<OrderProvider>(context, listen: false).fetchUserOrders(
            storeId: storeId,
            phone: phone,
          );
        }
      }
    });
  }

  void _showWalletModal(BuildContext context, double balance, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "UB Wallet Balance",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      "Instant 1-tap checkout & refunds",
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AVAILABLE BALANCE",
                    style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${balance.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        "Auto-applied during checkout",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text("Passbook", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Top-up feature is coming in next release! 🚀"),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text("Add Cash", style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "UB Mart Help & Support 🎧",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              "Need help with your current delivery, order, or refund?",
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _buildSupportTile(
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF0284C7),
              title: "Chat with Delivery Assistant",
              subtitle: "Instant response for active deliveries",
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Connecting to UB Support Assistant..."),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildSupportTile(
              icon: Icons.phone_in_talk_rounded,
              color: const Color(0xFF10B981),
              title: "Call Support Helpline",
              subtitle: "Toll-Free: 1800-UB-MART (7 AM - 11 PM)",
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Calling Toll-free 1800-82-6278..."),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildSupportTile(
              icon: Icons.mail_outline_rounded,
              color: const Color(0xFFF59E0B),
              title: "Email Support",
              subtitle: "support@ubmart.in",
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Write to us at support@ubmart.in"),
                    backgroundColor: AppTheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);
    final favProvider = Provider.of<FavoritesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authProvider.user;

    final allOrders = orderProvider.userOrders;
    final activeOrders = allOrders
        .where((o) => o.status != 'DELIVERED' && o.status != 'CANCELLED')
        .toList();
    final OrderModel? mostRecentActiveOrder = activeOrders.isNotEmpty ? activeOrders.first : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0B0F19) : Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          "My Account",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Customer Support",
            icon: Icon(
              Icons.headset_mic_outlined,
              color: isDark ? Colors.white70 : const Color(0xFF0F172A),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSupportModal(context, isDark);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. MODERN USER PROFILE CARD ──
            if (authProvider.isLoggedIn && user != null)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar with Gradient Ring & Verified Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primary,
                                const Color(0xFFF59E0B),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : "U",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name.isNotEmpty ? user.name : "Valued Member",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "VIP ⚡",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_android_rounded,
                                size: 13,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "+91 ${user.phone}",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Edit Profile Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Edit",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Logged Out Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
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
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.person_rounded, size: 28, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome to UB Mart!",
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Sign in to track deliveries & access wallet",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text(
                          "LOGIN / SIGN UP",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 14),

            // ── 2. LIVE ACTIVE ORDER TRACKER HERO BANNER (If Active Delivery) ──
            if (mostRecentActiveOrder != null) ...[
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderTrackingScreen(order: mostRecentActiveOrder),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Text("🛵", style: TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    "LIVE TRACKING",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "#${mostRecentActiveOrder.orderId}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mostRecentActiveOrder.status == 'OUT_FOR_DELIVERY'
                                  ? "Rider is heading to you ⚡"
                                  : "Packing your fresh order 📦",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Tap to view on Google Maps",
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // ── 3. GROUPED LIST: ORDERS, WISHLIST & WALLET (All in Clean List) ──
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "MY ORDERS & WALLET",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Orders tile
                  _buildListTile(
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: "My Orders",
                    subtitle: activeOrders.isNotEmpty
                        ? "1 active delivery in progress ⚡"
                        : "${allOrders.length} past orders & invoices",
                    trailingWidget: activeOrders.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "LIVE 🛵",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                            ),
                          )
                        : (allOrders.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "${allOrders.length}",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              )
                            : null),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 64),

                  // Wishlist tile
                  _buildListTile(
                    icon: Icons.favorite_rounded,
                    iconColor: const Color(0xFFF43F5E),
                    title: "My Wishlist",
                    subtitle: "${favProvider.favoriteIds.length} items saved for quick purchase",
                    trailingWidget: favProvider.favoriteIds.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${favProvider.favoriteIds.length} Saved",
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFF43F5E)),
                            ),
                          )
                        : null,
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WishlistScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 64),

                  // UB Wallet tile
                  _buildListTile(
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "UB Wallet",
                    subtitle: "Instant 1-tap checkout & refunds",
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "₹${user?.walletBalance.toStringAsFixed(0) ?? '0'}",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                    ),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showWalletModal(context, user?.walletBalance ?? 0.0, isDark);
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 64),

                  // Saved Addresses tile
                  _buildListTile(
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: "Delivery Addresses",
                    subtitle: "${user?.addresses.length ?? 0} saved addresses",
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${user?.addresses.length ?? 0} Saved",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF0284C7)),
                      ),
                    ),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (authProvider.isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Please login to view saved addresses"),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 4. GROUPED SETTINGS: STORE & DISCOUNTS ──
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "STORE & OFFERS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Store Hub tile
                  _buildListTile(
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFFF97316),
                    title: "Delivery Store Hub",
                    subtitle: storeProvider.selectedStore?.name ?? "Select Delivery Hub",
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Change",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF97316)),
                      ),
                    ),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                      );
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 64),

                  // Coupons & Offers tile
                  _buildListTile(
                    icon: Icons.confirmation_num_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "Coupons & Discounts",
                    subtitle: "View exclusive promo codes & instant discounts",
                    trailingWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Offers 🏷️",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF8B5CF6)),
                      ),
                    ),
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Use code WELCOME50 for instant discounts at checkout! 🏷️"),
                          backgroundColor: const Color(0xFF8B5CF6),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 5. GROUPED SETTINGS: SUPPORT & POLICIES ──
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                "HELP & LEGAL",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Customer Support tile
                  _buildListTile(
                    icon: Icons.headset_mic_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: "Help & Customer Support",
                    subtitle: "Instant chat, phone helpline & FAQs",
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showSupportModal(context, isDark);
                    },
                  ),
                  Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade100, indent: 64),

                  // Privacy & Security tile
                  _buildListTile(
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: "Privacy & Terms",
                    subtitle: "100% safe payments & data protection",
                    isDark: isDark,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Terms & Privacy Policy", style: TextStyle(fontWeight: FontWeight.w900)),
                          content: const Text(
                            "UB Mart is committed to protecting your privacy and delivering genuine grocery products with 100% hygiene and express delivery standards.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("Got It", style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 6. LOG OUT BUTTON ──
            if (authProvider.isLoggedIn) ...[
              InkWell(
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: const Text("Log Out?", style: TextStyle(fontWeight: FontWeight.w900)),
                      content: const Text("Are you sure you want to log out of your UB Mart account?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authProvider.logout();
                    if (context.mounted) {
                      Provider.of<FavoritesProvider>(context, listen: false).clearFavorites();
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Log Out of Account",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── 7. FOOTER BRANDING ──
            Center(
              child: Column(
                children: [
                  Text(
                    "UB Mart • Quick Commerce v1.0.0",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white38 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Ultra-Fast Express Grocery Delivery in 10-15 mins ⚡",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white24 : Colors.grey.shade400,
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

  // ── GROUPED LIST TILE ──
  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? trailingWidget,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
