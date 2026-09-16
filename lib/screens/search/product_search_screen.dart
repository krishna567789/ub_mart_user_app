import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/cart_bottom_bar.dart';
import '../../widgets/smart_image.dart';
import '../../widgets/custom_text.dart';
import '../../widgets/voice_search_modal.dart';
import '../../theme/app_theme.dart';
import '../cart_screen.dart';
import '../product_list_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  final String? initialQuery;
  final bool autoFocus;

  const ProductSearchScreen({
    super.key,
    this.initialQuery,
    this.autoFocus = true,
  });

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounceTimer;
  bool _isLoading = false;
  List<ProductModel> _searchResults = [];
  String _activeQuery = '';

  // Filter & Sort State
  String _selectedSortBy =
      ''; // '', 'price_low', 'price_high', 'rating', 'discount'
  String? _selectedBrand;
  bool _inStockOnly = false;
  List<String> _extractedBrands = [];

  // Recent Searches
  List<String> _recentSearches = [];
  static const String _prefRecentKey = 'ub_recent_searches';

  // Popular / Trending Queries
  final List<Map<String, String>> _trendingSearches = const [
    {'label': 'Fresh Milk', 'icon': '🥛'},
    {'label': 'Amul Butter', 'icon': '🧈'},
    {'label': 'Aashirvaad Atta', 'icon': '🌾'},
    {'label': 'Bread & Eggs', 'icon': '🍞'},
    {'label': 'Maggi Noodles', 'icon': '🍜'},
    {'label': 'Lays Chips', 'icon': '🥔'},
    {'label': 'Cold Drinks', 'icon': '🥤'},
    {'label': 'Dairy Milk', 'icon': '🍫'},
    {'label': 'Tea & Coffee', 'icon': '☕'},
    {'label': 'Onion & Potato', 'icon': '🧅'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();

    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
      _activeQuery = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _executeSearch(_activeQuery);
      });
    }

    // Preload category tree if not loaded yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = Provider.of<StoreProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      final storeId = store.selectedStore?.id ?? '';
      if (productProvider.categories.isEmpty) {
        productProvider.fetchMainCategoriesTree(storeId);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Load Recent Searches from SharedPreferences
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_prefRecentKey) ?? [];
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent searches: $e');
    }
  }

  // Save Recent Search
  Future<void> _saveRecentSearch(String term) async {
    final clean = term.trim();
    if (clean.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = List<String>.from(_recentSearches);
      list.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
      list.insert(0, clean);
      if (list.length > 10) list = list.sublist(0, 10);

      await prefs.setStringList(_prefRecentKey, list);
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  // Remove individual recent search
  Future<void> _removeRecentSearch(String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = List<String>.from(_recentSearches);
      list.removeWhere((item) => item.toLowerCase() == term.toLowerCase());
      await prefs.setStringList(_prefRecentKey, list);
      if (mounted) {
        setState(() {
          _recentSearches = list;
        });
      }
    } catch (e) {
      debugPrint('Error removing recent search: $e');
    }
  }

  // Clear all recent searches
  Future<void> _clearAllRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefRecentKey);
      if (mounted) {
        setState(() {
          _recentSearches.clear();
        });
      }
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  // Debounced Search Handler
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 320), () {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        setState(() {
          _activeQuery = '';
          _searchResults.clear();
          _extractedBrands.clear();
          _selectedBrand = null;
          _isLoading = false;
        });
        return;
      }

      _executeSearch(trimmed);
    });
  }

  // Execute High-Performance API Search
  Future<void> _executeSearch(String query) async {
    final store = Provider.of<StoreProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final storeId = store.selectedStore?.id ?? '';

    setState(() {
      _isLoading = true;
      _activeQuery = query;
    });

    _saveRecentSearch(query);

    final results = await productProvider.searchProductsApi(
      storeId,
      query,
      brand: _selectedBrand,
      sortBy: _selectedSortBy,
      inStockOnly: _inStockOnly,
    );

    if (!mounted) return;

    // Extract unique brands for instant facet filtering
    final brandSet = <String>{};
    for (var p in results) {
      if (p.brand != null && p.brand!.trim().isNotEmpty) {
        brandSet.add(p.brand!.trim());
      }
    }

    setState(() {
      _searchResults = results;
      _extractedBrands = brandSet.toList()..sort();
      _isLoading = false;
    });
  }

  // Animated Voice Search Modal
  void _openVoiceSearchModal() {
    VoiceSearchModal.show(
      context,
      onQuerySelected: (query) {
        _searchController.text = query;
        _executeSearch(query);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : const Color(0xFFF8FAFC),
      appBar: _buildSearchAppBar(isDark),
      body: Column(
        children: [
          // Filter & Sort Bar (When search has active results)
          if (_activeQuery.isNotEmpty &&
              !_isLoading &&
              _searchResults.isNotEmpty)
            _buildFiltersAndSortBar(isDark),

          // Main Body: Search Results OR Recommendations / History
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer(isDark)
                : _activeQuery.isEmpty
                ? _buildEmptyQueryContent(isDark)
                : _searchResults.isEmpty
                ? _buildNoResultsState(isDark)
                : _buildSearchResultsGrid(isDark),
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

  // Top App Bar with Interactive Search Field
  PreferredSizeWidget _buildSearchAppBar(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          12,
          MediaQuery.of(context).padding.top + 6,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back Button
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),

            // Search Input Field
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppTheme.primary
                        : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.search_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _focusNode,
                        autofocus: widget.autoFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: _onSearchChanged,
                        onSubmitted: (term) {
                          if (term.trim().isNotEmpty) {
                            _executeSearch(term.trim());
                          }
                        },
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: "Search 5,000+ groceries, snacks, dairy...",
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                    GestureDetector(
                      onTap: _openVoiceSearchModal,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          size: 18,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter & Sorting Quick Chips
  Widget _buildFiltersAndSortBar(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          // Results Counter Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomText(
              "${_searchResults.length} items",
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),

          // In-Stock Only Pill
          _buildFilterChip(
            label: "In Stock",
            isSelected: _inStockOnly,
            icon: Icons.check_circle_outline_rounded,
            onTap: () {
              setState(() => _inStockOnly = !_inStockOnly);
              _executeSearch(_activeQuery);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Price: Low to High
          _buildFilterChip(
            label: "Price: Low to High",
            isSelected: _selectedSortBy == 'price_low',
            icon: Icons.arrow_upward_rounded,
            onTap: () {
              setState(() {
                _selectedSortBy = _selectedSortBy == 'price_low'
                    ? ''
                    : 'price_low';
              });
              _executeSearch(_activeQuery);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Price: High to Low
          _buildFilterChip(
            label: "Price: High to Low",
            isSelected: _selectedSortBy == 'price_high',
            icon: Icons.arrow_downward_rounded,
            onTap: () {
              setState(() {
                _selectedSortBy = _selectedSortBy == 'price_high'
                    ? ''
                    : 'price_high';
              });
              _executeSearch(_activeQuery);
            },
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Top Rated
          _buildFilterChip(
            label: "Top Rated",
            isSelected: _selectedSortBy == 'rating',
            icon: Icons.star_rounded,
            onTap: () {
              setState(() {
                _selectedSortBy = _selectedSortBy == 'rating' ? '' : 'rating';
              });
              _executeSearch(_activeQuery);
            },
            isDark: isDark,
          ),

          // Dynamic Brand Chips
          for (var brand in _extractedBrands.take(6)) ...[
            const SizedBox(width: 8),
            _buildFilterChip(
              label: brand,
              isSelected: _selectedBrand == brand,
              onTap: () {
                setState(() {
                  _selectedBrand = _selectedBrand == brand ? null : brand;
                });
                _executeSearch(_activeQuery);
              },
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              const SizedBox(width: 4),
            ],
            CustomText(
              label,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  // Initial Empty State: Recent Searches + Trending Chips + Top Categories
  Widget _buildEmptyQueryContent(bool isDark) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        // Recent Searches Section
        if (_recentSearches.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    "Recent Searches",
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _clearAllRecentSearches();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const CustomText(
                    "Clear all",
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((term) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.02,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchController.text = term;
                      _executeSearch(term);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 6),
                          CustomText(
                            term,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _removeRecentSearch(term);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white12
                                    : const Color(0xFFF1F5F9),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 12,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],

        // Trending Searches
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                CustomText(
                  "Trending Searches",
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("🔥", style: TextStyle(fontSize: 10)),
                  SizedBox(width: 3),
                  CustomText(
                    "Hot in your area",
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD97706),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingSearches.map((item) {
            final label = item['label']!;
            final icon = item['icon']!;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _searchController.text = label;
                _executeSearch(label);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    CustomText(
                      label,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 28),

        // Browse Categories Shortcut Grid
        if (categories.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                "Explore Popular Categories",
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.take(8).length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 12,
              childAspectRatio: 0.76,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductListScreen(
                        title: cat.name,
                        categoryId: cat.id,
                      ),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SmartImage(
                          imageUrl: cat.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomText(
                      cat.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                      height: 1.15,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  // Search Results Grid
  Widget _buildSearchResultsGrid(bool isDark) {
    return Column(
      children: [
        // Express Delivery Banner Strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: "Delivery in ",
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    TextSpan(
                      text: "8–10 mins ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    TextSpan(
                      text: "• ${_searchResults.length} items found",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Products Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 40),
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
              childAspectRatio: 0.52,
            ),
            itemBuilder: (context, index) {
              final product = _searchResults[index];
              return ProductCard(product: product);
            },
          ),
        ),
      ],
    );
  }

  // No Results State with Intelligent Recommendations
  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 46,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 18),
            CustomText(
              "No products found for '$_activeQuery'",
              textAlign: TextAlign.center,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            const SizedBox(height: 8),
            const CustomText(
              "Please check spelling or search with generic terms like 'milk', 'chips', or 'soap'.",
              textAlign: TextAlign.center,
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const CustomText(
                "Clear Search & Explore",
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Skeleton Loader
  Widget _buildLoadingShimmer(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                width: 70,
                height: 12,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),

              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                height: 14,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
