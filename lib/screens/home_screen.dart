import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/store_provider.dart';
import '../providers/home_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../models/homepage_section_model.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/shimmer_loaders.dart';
import 'location_select_screen.dart';
import 'product_detail_screen.dart';
import 'product_list_screen.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _activeBannerIndex = 0;

  final List<String> _popularSuggestions = [
    "Milk", "Bread", "Eggs", "Atta", "Chips", "Cold Drinks", "Apples", "Butter"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final storeId = storeProvider.selectedStore?.id ?? '';
    if (storeId.isNotEmpty) {
      homeProvider.fetchHomeData(storeId);
      productProvider.fetchProducts(storeId);
      cartProvider.fetchCoupons(storeId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeProvider = Provider.of<StoreProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.white,
        elevation: 1,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LocationSelectScreen()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, color: AppTheme.accent, size: 14),
                        SizedBox(width: 2),
                        Text(
                          "10 MINS",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    storeProvider.selectedStore?.name ?? "Select Store Location",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: AppTheme.textPrimary, size: 20),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppTheme.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: homeProvider.isLoading
          ? SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: const [
                  BannerShimmer(),
                  SizedBox(height: 16),
                  CategoryShimmer(),
                  SizedBox(height: 16),
                  ProductHorizontalShimmer(),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) {
                          setState(() {});
                        },
                        decoration: InputDecoration(
                          hintText: "Search 'milk', 'chips', 'apple'...",
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ),

                    // Quick Search Suggestion Chips if user is searching or empty
                    if (_searchController.text.trim().isEmpty)
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _popularSuggestions.length,
                          itemBuilder: (context, index) {
                            final sug = _popularSuggestions[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(sug),
                                labelStyle: const TextStyle(fontSize: 11, color: AppTheme.textPrimary),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.grey.shade300),
                                onPressed: () {
                                  _searchController.text = sug;
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Search Mode vs Normal Mode
                    if (_searchController.text.trim().isNotEmpty)
                      _buildSearchResults(productProvider, _searchController.text.trim())
                    else ...[
                      // 1. Top Banners Slider
                      if (homeProvider.banners.isNotEmpty) ...[
                        SizedBox(
                          height: 140,
                          child: PageView.builder(
                            itemCount: homeProvider.banners.length,
                            controller: PageController(viewportFraction: 0.92),
                            onPageChanged: (idx) {
                              setState(() {
                                _activeBannerIndex = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              final banner = homeProvider.banners[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CachedNetworkImage(
                                    imageUrl: banner.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (ctx, url, err) => Container(
                                      color: AppTheme.primaryLight,
                                      child: Center(
                                        child: Text(
                                          banner.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Banner Page Dots
                        if (homeProvider.banners.length > 1)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(homeProvider.banners.length, (idx) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                width: _activeBannerIndex == idx ? 18 : 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _activeBannerIndex == idx ? AppTheme.primary : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 16),
                      ],

                      // 2. Main Categories Avatars Grid
                      if (homeProvider.mainCategories.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "Explore Categories",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 105,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: homeProvider.mainCategories.length,
                            itemBuilder: (context, index) {
                              final mc = homeProvider.mainCategories[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductListScreen(
                                        title: mc.name,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 78,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 62,
                                        height: 62,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade200),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 4,
                                            )
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: mc.image,
                                            fit: BoxFit.cover,
                                            errorWidget: (c, u, e) => const Icon(
                                              Icons.category,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        mc.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 3. Dynamic Homepage Sections from Admin Builder
                      for (var section in homeProvider.homepageSections)
                        _buildDynamicSection(section),

                      // 4. Popular Items Section
                      if (productProvider.products.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Popular Items",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProductListScreen(title: "All Products"),
                                    ),
                                  );
                                },
                                child: const Text("See All"),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: productProvider.products.length,
                            itemBuilder: (context, index) {
                              final product = productProvider.products[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailScreen(product: product),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
      bottomSheet: CartBottomBar(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(ProductProvider provider, String query) {
    final results = provider.searchProducts(query);

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 50, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                "No products found for '$query'",
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final p = results[index];
        return ProductCard(
          product: p,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDynamicSection(HomepageSectionModel section) {
    if (section.type == 'OFFER_STRIP') {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.local_offer, color: AppTheme.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                section.offerText,
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (section.type == 'PRODUCT_SCROLL' || section.type == 'FLASH_SALE') {
      if (section.products.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                if (section.type == 'FLASH_SALE')
                  const Padding(
                    padding: EdgeInsets.only(right: 6.0),
                    child: Icon(Icons.bolt, color: AppTheme.accent, size: 22),
                  ),
                Text(
                  section.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: section.products.length,
              itemBuilder: (context, index) {
                final product = section.products[index];
                return ProductCard(
                  product: product,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
