import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:un_mart_user_app/widgets/smart_image.dart';
import '../../widgets/custom_text.dart';
import '../../providers/home_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dashboard_active_order_card.dart';
import '../../utils/cart_animation_helper.dart';
import '../cart_screen.dart';
import 'widgets/homepage_section_parser.dart';
import 'package:shimmer/shimmer.dart';
import 'widgets/animated_delivery_eta.dart';
import 'widgets/animated_voice_search.dart';
import 'widgets/delivery_bike_loader.dart';
import '../location_select_screen.dart';
import '../profile_screen.dart';
import '../search/product_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  int _selectedCategoryIndex = 0;

  late AnimationController _cartBounceController;
  late Animation<double> _cartBounceAnimation;

  @override
  void initState() {
    super.initState();
    _cartBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _cartBounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.08,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 0.96,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_cartBounceController);

    CartAnimationHelper.cartBounceNotifier.addListener(_onCartBounceTrigger);

    _orderPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final orderProv = context.read<OrderProvider>();
      if (auth.isLoggedIn && auth.user != null && orderProv.activeOrder != null) {
        orderProv.fetchUserOrders(storeId: '', phone: auth.user!.phone);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  Timer? _orderPollTimer;

  void _onCartBounceTrigger() {
    if (mounted) {
      _cartBounceController.forward(from: 0.0);
    }
  }

  void _refreshAll() {
    context.read<HomeProvider>().fetchHomepage();
    context.read<SettingsProvider>().fetchSettings();
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn && auth.user != null) {
      context.read<OrderProvider>().fetchUserOrders(
        storeId: '',
        phone: auth.user!.phone,
      );
    }
  }

  @override
  void dispose() {
    _orderPollTimer?.cancel();
    CartAnimationHelper.cartBounceNotifier.removeListener(_onCartBounceTrigger);
    _cartBounceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Color> _getSeasonalGradientColors(BuildContext context, String? mode) {
    final primary = Theme.of(context).primaryColor;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (mode) {
      case 'WINTER':
      case 'CHRISTMAS':
        return [isDark ? const Color(0xFF0C4A6E) : const Color(0xFFBAE6FD), bg];
      case 'SUMMER':
        return [isDark ? const Color(0xFF451A03) : const Color(0xFFFED7AA), bg];
      case 'MONSOON':
        return [isDark ? const Color(0xFF064E3B) : const Color(0xFFA7F3D0), bg];
      case 'DIWALI':
        return [isDark ? const Color(0xFF450A0A) : const Color(0xFFFECDD3), bg];
      case 'SPRING':
        return [isDark ? const Color(0xFF500724) : const Color(0xFFFBCFE8), bg];
      default:
        return [primary, bg];
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final announcement = settingsProvider.settings?.announcementBar;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return DeliveryBikeLoader(
            onRefresh: () async => _refreshAll(),
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(context, settingsProvider, provider),
                if (announcement != null &&
                    announcement.isActive &&
                    announcement.text.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildAnnouncementBar(announcement),
                  ),

                // Active Order Live Tracking Card on Dashboard
                Consumer<OrderProvider>(
                  builder: (context, orderProv, _) {
                    final activeOrder = orderProv.activeOrder;
                    if (activeOrder == null) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    return SliverToBoxAdapter(
                      child: DashboardActiveOrderCard(order: activeOrder),
                    );
                  },
                ),

                if (provider.isLoading)
                  _buildShimmerLoading()
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error: ${provider.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isLight ? Colors.black87 : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _refreshAll,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (provider.sections.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No homepage sections found',
                        style: TextStyle(
                          color: isLight ? Colors.black54 : Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 130),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((
                        context,
                        index,
                      ) {
                        final section = provider.sections[index];
                        return HomepageSectionParser(section: section);
                      }, childCount: provider.sections.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Shimmer.fromColors(
            baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            highlightColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade100,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: 140,
                          margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: 3),
      ),
    );
  }

  Widget _buildAnnouncementBar(dynamic announcement) {
    Color bgColor = const Color(0xFFEF4444);
    try {
      if (announcement.bgColor.isNotEmpty) {
        String hex = announcement.bgColor.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        bgColor = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign, color: bgColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              announcement.text,
              style: TextStyle(
                color: bgColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    SettingsProvider settingsProvider,
    HomeProvider provider,
  ) {
    final seasonalMode = settingsProvider.settings?.seasonalTheme.mode;
    final gradientColors = _getSeasonalGradientColors(context, seasonalMode);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final primary = Theme.of(context).primaryColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final headerTextColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final headerSubtextColor = isLight
        ? const Color(0xFF475569)
        : Colors.white70;

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: scaffoldBg,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientColors[0], scaffoldBg],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
      expandedHeight: 220,
      toolbarHeight: 65,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withOpacity(0.9)
                    : const Color(0xFF0D1B2A).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLight
                      ? Colors.black.withOpacity(0.08)
                      : primary.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isLight ? 0.06 : 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: primary, size: 18),
                  const SizedBox(width: 4),
                  Builder(
                    builder: (context) {
                      final hour = DateTime.now().hour;
                      String greeting = "Good Morning";
                      if (hour >= 12 && hour < 17) greeting = "Good Afternoon";
                      if (hour >= 17) greeting = "Good Evening";

                      return Text(
                        "$greeting, ",
                        style: TextStyle(
                          color: isLight
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                  Text(
                    "Uday",
                    style: TextStyle(
                      color: isLight ? const Color(0xFF0F172A) : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    "Bharat",
                    style: TextStyle(
                      color: primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            // Right Badges
            Row(
              children: [
                const SizedBox(width: 8),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isLight
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black45,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isLight ? 0.08 : 0.2,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none,
                        color: isLight ? const Color(0xFF1E293B) : Colors.white,
                        size: 18,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: isLight
                        ? Colors.white.withOpacity(0.9)
                        : Colors.white12,
                    child: Icon(
                      Icons.person,
                      color: isLight ? const Color(0xFF1E293B) : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(152),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Row
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationSelectScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: headerTextColor, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tower B, Cyber Hub",
                            style: TextStyle(
                              color: headerTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                "DLF Ph 2 ",
                                style: TextStyle(
                                  color: headerSubtextColor,
                                  fontSize: 11,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: headerSubtextColor,
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const AnimatedDeliveryEta(),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Search Bar
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductSearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : const Color(0xFF1F222A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isLight
                          ? Colors.black.withOpacity(0.08)
                          : Colors.white10,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isLight ? 0.06 : 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.search, color: primary, size: 20),
                      ),
                      Expanded(
                        child: Text(
                          'Search Alphonso mangoes, Greek y...',
                          style: TextStyle(
                            color: isLight
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: isLight
                              ? Colors.grey.shade600
                              : Colors.grey.shade500,
                          size: 18,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 20,
                        color: isLight ? Colors.grey.shade300 : Colors.white10,
                      ),
                      const AnimatedVoiceSearch(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dynamic Main Categories as Tabs
              if (provider.mainCategories.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(provider.mainCategories.length, (
                      index,
                    ) {
                      final category = provider.mainCategories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(
                          left: index == 0 ? 0 : 8.0,
                          right: index == provider.mainCategories.length - 1
                              ? 16.0
                              : 0,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isLight
                                        ? primary.withOpacity(0.18)
                                        : Colors.white.withOpacity(0.15))
                                  : (isLight
                                        ? Colors.white.withOpacity(0.85)
                                        : Colors.transparent),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : (isLight
                                          ? Colors.black.withOpacity(0.08)
                                          : Colors.white10),
                              ),
                              boxShadow: isLight && isSelected
                                  ? [
                                      BoxShadow(
                                        color: primary.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (category.image.isNotEmpty) ...[
                                  ClipOval(
                                    child: Container(
                                      color: const Color(0xFFF1F5F9),
                                      width: 16,
                                      height: 16,
                                      child: SmartImage(
                                        imageUrl: category.image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                CustomText(
                                  category.name,
                                  color: isSelected
                                      ? (isLight
                                            ? const Color(0xFF0F172A)
                                            : primary)
                                      : (isLight
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade400),
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingCart(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        if (cart.itemCount == 0) return const SizedBox.shrink();
        final primaryColor = Theme.of(context).primaryColor;
        final totalSavings = cart.totalSavings;
        final totalMrp = cart.totalMrp;
        final displayedItems = cart.itemList.take(3).toList();
        final remainingCount = cart.itemList.length - displayedItems.length;
        return ScaleTransition(
          scale: _cartBounceAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            child: Container(
              key: CartAnimationHelper.cartTargetKey,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), // sleek dark slate
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top guaranteed delivery bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              "Locked: 8–10 Min Guaranteed Delivery",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        if (totalSavings > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFD97706),
                                  size: 12,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  "Saved ₹${totalSavings.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    color: Color(0xFFB45309),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Express Dispatch",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Item Avatars stack (shows real cart items)
                            SizedBox(
                              width:
                                  (displayedItems.length.clamp(1, 3) * 18.0) +
                                  (remainingCount > 0 ? 32.0 : 16.0),
                              height: 32,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  for (
                                    int i = 0;
                                    i < displayedItems.length;
                                    i++
                                  )
                                    Positioned(
                                      left: i * 18.0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: const Color(0xFF0F172A),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: SmartImage(
                                            imageUrl:
                                                displayedItems[i]
                                                    .product
                                                    .images
                                                    .isNotEmpty
                                                ? displayedItems[i]
                                                      .product
                                                      .images
                                                      .first
                                                : '',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (remainingCount > 0)
                                    Positioned(
                                      left: displayedItems.length * 18.0,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primaryColor,
                                          border: Border.all(
                                            color: const Color(0xFF0F172A),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "+$remainingCount",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "₹${cart.grandTotal.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (totalSavings > 0) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        "₹${totalMrp.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  "${cart.itemCount} ${cart.itemCount == 1 ? 'item' : 'items'} • Ready",
                                  style: const TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Swipe Pay Button
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(13),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Swipe Pay",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.black,
                                size: 15,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
