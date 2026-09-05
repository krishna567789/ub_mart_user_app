import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/store_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_bottom_bar.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String title;
  final String? subCategoryId;

  const ProductListScreen({
    Key? key,
    required this.title,
    this.subCategoryId,
  }) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);

      final storeId = storeProvider.selectedStore?.id ?? '';
      if (storeId.isNotEmpty) {
        productProvider.fetchProducts(storeId, subCategoryId: widget.subCategoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : productProvider.products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        "No products in ${widget.title}",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    final p = productProvider.products[index];
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
