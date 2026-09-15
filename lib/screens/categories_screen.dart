import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/main_category_model.dart';
import '../models/category_model.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_text.dart';
import '../widgets/smart_image.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/shimmer_loaders.dart';
import '../utils/app_sizes.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All';

  // Soft pastel background card colors matching the homepage aesthetic
  static const List<Color> _cardColors = [
    Color(0xFFE8F0FE), // Soft Pastel Blue
    Color(0xFFFFEAEA), // Soft Pastel Pink/Red
    Color(0xFFE0F7FA), // Soft Pastel Teal/Cyan
    Color(0xFFF3E5F5), // Soft Pastel Purple
    Color(0xFFFFF3E0), // Soft Pastel Orange
    Color(0xFFE8F5E9), // Soft Pastel Green
    Color(0xFFFFF8E1), // Soft Pastel Yellow
    Color(0xFFEDE7F6), // Soft Pastel Lavender
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final storeId = storeProvider.selectedStore?.id ?? '';
    await productProvider.fetchMainCategoriesTree(storeId);
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final storeProvider = Provider.of<StoreProvider>(context);
    final mainCategories = productProvider.mainCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Filter main categories based on filter chip and search query
    List<MainCategoryModel> displayMainCategories = mainCategories;
    if (_activeFilter != 'All') {
      displayMainCategories = mainCategories
          .where((m) => m.name.toLowerCase() == _activeFilter.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      displayMainCategories = displayMainCategories.where((m) {
        final matchesMain = m.name.toLowerCase().contains(_searchQuery);
        final matchesCat = m.categories.any(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery) ||
              c.subCategories.any(
                (s) => s.name.toLowerCase().contains(_searchQuery),
              ),
        );
        return matchesMain || matchesCat;
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          "All Categories",
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        centerTitle: false,
        elevation: 0,
      ),
      bottomNavigationBar: CartBottomBar(onTap: () {}),
      body: Column(
        children: [
          // ── Top Header Search Bar & Filter Chips ──
          Container(
            padding: EdgeInsets.fromLTRB(
              context.r(16),
              context.r(4),
              context.r(16),
              context.r(10),
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Input Box
                Container(
                  height: context.r(42),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(context.r(12)),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: "Search categories, snacks, drinks...",
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: context.r(20),
                        color: primaryColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: context.r(10),
                      ),
                    ),
                  ),
                ),

                // Horizontal Filter Chips (All, Fruits & Vegetables, Grocery & Kitchen, etc.)
                if (mainCategories.isNotEmpty) ...[
                  SizedBox(height: context.r(8)),
                  SizedBox(
                    height: context.r(30),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All', isDark, primaryColor),
                        ...mainCategories.map(
                          (m) => _buildFilterChip(m.name, isDark, primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Vertical Main Category Sections (Full Width Column, 4-column GridView) ──
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCategories,
              color: primaryColor,
              child: productProvider.isLoading && mainCategories.isEmpty
                  ? _buildSkeletonLoader(context, isDark)
                  : displayMainCategories.isEmpty
                  ? _buildEmptyState(context, isDark, storeProvider)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: context.r(8)),
                      itemCount: displayMainCategories.length,
                      itemBuilder: (context, index) {
                        final mainCat = displayMainCategories[index];
                        return _buildMainCategorySection(
                          context,
                          mainCat,
                          isDark,
                          primaryColor,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark, Color primaryColor) {
    final isSelected = _activeFilter.toLowerCase() == label.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = label;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: context.r(6)),
        padding: EdgeInsets.symmetric(
          horizontal: context.r(12),
          vertical: context.r(4),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(context.r(16)),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: CustomText(
            label,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategorySection(
    BuildContext context,
    MainCategoryModel mainCat,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: context.r(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Main Category Header Title + View All > ──
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.r(16),
              context.r(12),
              context.r(16),
              context.r(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    mainCat.name,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductListScreen(title: mainCat.name),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      CustomText(
                        "View All",
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                      SizedBox(width: context.r(2)),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: context.r(16),
                        color: primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Direct 4-Column GridView of Categories under this Main Category ──
          if (mainCat.categories.isEmpty)
            _buildEmptyCategorySection(context, isDark, mainCat, primaryColor)
          else
            _buildDirectCategoryGrid(
              context,
              mainCat.categories,
              isDark,
              primaryColor,
            ),
        ],
      ),
    );
  }

  Widget _buildDirectCategoryGrid(
    BuildContext context,
    List<CategoryModel> categories,
    bool isDark,
    Color primaryColor,
  ) {
    final displayCats = _searchQuery.isEmpty
        ? categories
        : categories
              .where((c) => c.name.toLowerCase().contains(_searchQuery))
              .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: context.r(16),
        vertical: context.r(6),
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: context.r(12),
        crossAxisSpacing: context.r(10),
        childAspectRatio: 0.72,
      ),
      itemCount: displayCats.length,
      itemBuilder: (context, index) {
        final cat = displayCats[index];
        final color = _cardColors[index % _cardColors.length];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ProductListScreen(title: cat.name, categoryId: cat.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(context.r(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Soft Pastel Card Container
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? color.withValues(alpha: 0.18) : color,
                    borderRadius: BorderRadius.circular(context.r(14)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(context.r(8)),
                  child: Center(
                    child: SmartImage(imageUrl: cat.image, fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height: context.r(5)),

              // Category Title
              Expanded(
                child: CustomText(
                  cat.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.15,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCategorySection(
    BuildContext context,
    bool isDark,
    MainCategoryModel mainCat,
    Color primaryColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: context.r(12),
        horizontal: context.r(16),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_bag_outlined, size: 18, color: primaryColor),
          SizedBox(width: context.r(8)),
          Expanded(
            child: CustomText(
              "Browse products in ${mainCat.name}",
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductListScreen(title: mainCat.name),
                ),
              );
            },
            child: const CustomText(
              "Explore",
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context, bool isDark) {
    return AdaptiveShimmer(
      child: ListView.builder(
        padding: EdgeInsets.all(context.r(16)),
        itemCount: 3,
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: context.r(140),
              height: context.r(18),
              margin: EdgeInsets.only(bottom: context.r(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: context.r(10),
                mainAxisSpacing: context.r(12),
                childAspectRatio: 0.72,
              ),
              itemCount: 4,
              itemBuilder: (_, __) => Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(14)),
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(6)),
                  Container(
                    width: context.r(45),
                    height: context.r(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.r(20)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    StoreProvider storeProvider,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.r(24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(context.r(20)),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: context.r(48),
                color: isDark ? Colors.white54 : Colors.grey.shade400,
              ),
            ),
            SizedBox(height: context.r(16)),
            CustomText(
              "No Categories found",
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            SizedBox(height: context.r(8)),
            CustomText(
              "Pull down or tap retry to load fresh categories",
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.r(20)),
            ElevatedButton.icon(
              onPressed: () async {
                if (storeProvider.selectedStore == null) {
                  await storeProvider.initStore();
                }
                await _loadCategories();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: context.r(28),
                  vertical: context.r(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(12)),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const CustomText(
                "Retry",
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
