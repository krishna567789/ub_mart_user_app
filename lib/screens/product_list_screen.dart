import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/custom_text.dart';
import '../widgets/smart_image.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_bar.dart';
import '../widgets/shimmer_loaders.dart';
import '../utils/app_sizes.dart';
import 'cart_screen.dart';
import 'search/product_search_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String title;
  final String? subCategoryId;
  final String? categoryId;
  final String? initialSearch;

  const ProductListScreen({
    super.key,
    required this.title,
    this.subCategoryId,
    this.categoryId,
    this.initialSearch,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedSubCategoryId = widget.subCategoryId;
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    final storeId = storeProvider.selectedStore?.id ?? '';
    String? catId = widget.categoryId;

    // Ensure category tree is loaded if provider is currently empty
    if (productProvider.categories.isEmpty) {
      await productProvider.fetchMainCategoriesTree(storeId);
    }

    // If categoryId is missing, find matching category by title from categories list
    if ((catId == null || catId.isEmpty) &&
        productProvider.categories.isNotEmpty) {
      final matches = productProvider.categories.where(
        (c) => c.name.trim().toLowerCase() == widget.title.trim().toLowerCase(),
      );
      if (matches.isNotEmpty) {
        catId = matches.first.id;
      }
    }

    // Always fetch subcategories for this category (or category title fallback)
    await productProvider.fetchSubCategories(
      storeId,
      categoryId: catId ?? widget.title,
    );

    // Fetch products for selected category/subCategory
    await _fetchProductsForCurrentSelection(effectiveCatId: catId);
  }

  Future<void> _fetchProductsForCurrentSelection({
    String? query,
    String? effectiveCatId,
  }) async {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final storeId = storeProvider.selectedStore?.id ?? '';

    final catIdToUse = effectiveCatId ?? widget.categoryId;

    await productProvider.fetchProducts(
      storeId,
      subCategoryId: _selectedSubCategoryId,
      categoryId: _selectedSubCategoryId == null ? catIdToUse : null,
      search:
          query ??
          (_searchController.text.isNotEmpty
              ? _searchController.text.trim()
              : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final subCats = productProvider.subCategories;
    final products = productProvider.products;
    final hasSubCats = subCats.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          widget.title,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Left Sidebar (Subcategories) if subcategories exist or loading ──
          if (hasSubCats || (productProvider.isLoading && subCats.isEmpty))
            Container(
              width: context.r(100),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF8FAFC),
                border: Border(
                  right: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: productProvider.isLoading && subCats.isEmpty
                  ? const SubcategorySidebarShimmer()
                  : ListView(
                      padding: EdgeInsets.symmetric(vertical: context.r(8)),
                      children: [
                        // 'All' Subcategory Option
                        _buildSubCategoryTile(
                          context,
                          id: null,
                          name: 'All',
                          imageUrl: '',
                          isSelected: _selectedSubCategoryId == null,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),

                        // Subcategory items
                        ...subCats.map((sc) {
                          return _buildSubCategoryTile(
                            context,
                            id: sc.id,
                            name: sc.name,
                            imageUrl: sc.image,
                            isSelected: _selectedSubCategoryId == sc.id,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          );
                        }),
                      ],
                    ),
            ),

          // ── Right Area: Products GridView with Filter Bar ──
          Expanded(
            child: Column(
              children: [
                // Top Filter & Sort Row
                Container(
                  height: context.r(40),
                  padding: EdgeInsets.symmetric(
                    horizontal: context.r(10),
                    vertical: context.r(4),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0xFF334155)
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterPill(
                        context,
                        icon: Icons.tune_rounded,
                        label: "Filters ▾",
                        isDark: isDark,
                      ),
                      SizedBox(width: context.r(8)),
                      _buildFilterPill(
                        context,
                        icon: Icons.swap_vert_rounded,
                        label: "Sort ▾",
                        isDark: isDark,
                      ),
                      SizedBox(width: context.r(8)),
                      _buildFilterPill(
                        context,
                        icon: null,
                        label: "Brand ▾",
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                // Products list content
                Expanded(
                  child: productProvider.isLoading
                      ? ProductGridShimmer(
                          childAspectRatio:
                              (hasSubCats || productProvider.isLoading)
                              ? 0.54
                              : 0.62,
                        )
                      : products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: context.r(54),
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey.shade400,
                              ),
                              SizedBox(height: context.r(12)),
                              CustomText(
                                "No products found",
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                              ),
                              SizedBox(height: context.r(12)),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _fetchProductsForCurrentSelection(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      context.r(10),
                                    ),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 16,
                                ),
                                label: const CustomText(
                                  "Refresh",
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: EdgeInsets.all(context.r(10)),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: hasSubCats ? 0.54 : 0.62,
                                crossAxisSpacing: context.r(8),
                                mainAxisSpacing: context.r(8),
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final p = products[index];
                            return ProductCard(product: p);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CartBottomBar(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          );
        },
      ),
    );
  }

  Widget _buildSubCategoryTile(
    BuildContext context, {
    required String? id,
    required String name,
    required String imageUrl,
    required bool isSelected,
    required bool isDark,
    required Color primaryColor,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubCategoryId = id;
        });
        _fetchProductsForCurrentSelection();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          vertical: context.r(10),
          horizontal: context.r(6),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF0F172A) : Colors.white)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3.5,
            ),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: context.r(42),
              height: context.r(42),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? SmartImage(imageUrl: imageUrl, fit: BoxFit.cover)
                    : Icon(
                        Icons.category_rounded,
                        size: context.r(20),
                        color: isSelected ? primaryColor : Colors.grey,
                      ),
              ),
            ),
            SizedBox(height: context.r(5)),
            CustomText(
              name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    BuildContext context, {
    required IconData? icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.r(10),
        vertical: context.r(4),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(context.r(8)),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            SizedBox(width: context.r(4)),
          ],
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF334155),
          ),
        ],
      ),
    );
  }
}
