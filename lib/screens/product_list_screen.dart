import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_bar.dart';
import 'cart_screen.dart';

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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
      _isSearching = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadProducts({String? query}) {
    final storeProvider = Provider.of<StoreProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    final storeId = storeProvider.selectedStore?.id ?? '';
    if (storeId.isNotEmpty) {
      productProvider.fetchProducts(
        storeId,
        subCategoryId: widget.subCategoryId,
        categoryId: widget.categoryId,
        search: query ?? (_searchController.text.isNotEmpty ? _searchController.text.trim() : null),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search products, brands...",
                  border: InputBorder.none,
                ),
                onChanged: (val) => _loadProducts(query: val),
              )
            : Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _loadProducts(query: '');
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: productProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : productProvider.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        "No products found",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _loadProducts(),
                        child: const Text("Refresh"),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final p = productProvider.products[index];
                    return ProductCard(product: p);
                  },
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
}
