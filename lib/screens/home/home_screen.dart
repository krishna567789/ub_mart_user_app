import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/store_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../cart_screen.dart';
import '../location_select_screen.dart';
import '../profile_screen.dart';
import '../product_list_screen.dart';
import 'widgets/homepage_section_parser.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAll();
    });
  }

  void _refreshAll() {
    context.read<HomeProvider>().fetchHomepage();
    context.read<SettingsProvider>().fetchSettings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Color> _getSeasonalGradientColors(BuildContext context, String? mode) {
    final primary = Theme.of(context).primaryColor;
    switch (mode) {
      case 'WINTER':
      case 'CHRISTMAS':
        return [const Color(0xFFE0F2FE), Colors.white];
      case 'SUMMER':
        return [const Color(0xFFFEF3C7), Colors.white];
      case 'MONSOON':
        return [const Color(0xFFCCFBF1), Colors.white];
      case 'DIWALI':
        return [const Color(0xFFFEF08A), Colors.white];
      case 'SPRING':
        return [const Color(0xFFFCE7F3), Colors.white];
      default:
        return [primary.withOpacity(0.15), Colors.white];
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final announcement = settingsProvider.settings?.announcementBar;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      bottomNavigationBar: _buildFloatingCart(context),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async => _refreshAll(),
            child: CustomScrollView(
              slivers: [
                _buildSliverHeader(context, settingsProvider),
                
                // Dynamic Announcement Bar if active in Admin Settings
                if (announcement != null && announcement.isActive && announcement.text.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildAnnouncementBar(announcement),
                  ),

                if (provider.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.error != null)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${provider.error}', textAlign: TextAlign.center),
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
                  const SliverFillRemaining(
                    child: Center(child: Text('No homepage sections found')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final section = provider.sections[index];
                          return HomepageSectionParser(section: section);
                        },
                        childCount: provider.sections.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

  Widget _buildFloatingCart(BuildContext context) {
    return Consumer2<CartProvider, SettingsProvider>(
      builder: (context, cart, settingsProvider, child) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        final currency = settingsProvider.settings?.currencySymbol ?? '₹';
        final primaryColor = Theme.of(context).primaryColor;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.itemCount} ${cart.itemCount == 1 ? "item" : "items"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '$currency${cart.grandTotal.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverHeader(BuildContext context, SettingsProvider settingsProvider) {
    final seasonalMode = settingsProvider.settings?.seasonalTheme.mode;
    final gradientColors = _getSeasonalGradientColors(context, seasonalMode);

    return SliverAppBar(
      pinned: true,
      floating: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 0.45],
          ),
        ),
      ),
      expandedHeight: 140,
      toolbarHeight: 65,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Consumer2<StoreProvider, AuthProvider>(
                builder: (context, storeProvider, authProvider, child) {
                  final storeName = storeProvider.selectedStore?.name ?? 'UB Mart Express';
                  final userAddress = authProvider.user != null && authProvider.user!.addresses.isNotEmpty
                      ? authProvider.user!.addresses.first.completeAddress
                      : storeName;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Delivery in 10 minutes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                userAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 16, color: Colors.black),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, size: 30, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductListScreen(title: "All Products"),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, color: Colors.grey),
                  ),
                  Expanded(
                    child: Text(
                      'Search "Milk", "Atta", "Chips"...',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.mic, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
