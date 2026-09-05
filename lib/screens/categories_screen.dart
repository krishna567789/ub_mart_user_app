import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/store_provider.dart';
import '../providers/home_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import 'product_list_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final storeId = storeProvider.selectedStore?.id ?? '';
      if (storeId.isNotEmpty) {
        productProvider.fetchCategories(storeId);
        productProvider.fetchSubCategories(storeId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    final mainCategories = homeProvider.mainCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories"),
        centerTitle: false,
      ),
      body: mainCategories.isEmpty
          ? const Center(child: Text("No Categories found"))
          : Row(
              children: [
                // Left Navigation Sidebar
                Container(
                  width: 100,
                  color: Colors.grey.shade100,
                  child: ListView.builder(
                    itemCount: mainCategories.length,
                    itemBuilder: (context, index) {
                      final mc = mainCategories[index];
                      final isSelected = _selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? AppTheme.primary : Colors.transparent,
                                width: 4,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: mc.image,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(Icons.category, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                mc.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right Content SubCategories Grid
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            mainCategories[_selectedIndex].name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: productProvider.subCategories.isEmpty
                              ? const Center(child: Text("Select subcategory to explore items"))
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: productProvider.subCategories.length,
                                  itemBuilder: (context, index) {
                                    final sc = productProvider.subCategories[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProductListScreen(
                                              title: sc.name,
                                              subCategoryId: sc.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        children: [
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              color: AppTheme.background,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: CachedNetworkImage(
                                                imageUrl: sc.image,
                                                fit: BoxFit.cover,
                                                errorWidget: (c, u, e) => const Icon(
                                                  Icons.shopping_basket_outlined,
                                                  color: AppTheme.primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            sc.name,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
