import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/homepage_section.dart';
import '../../../providers/product_provider.dart';
import '../../../widgets/smart_image.dart';
import '../../../widgets/custom_text.dart';
import '../../../utils/app_sizes.dart';
import '../../product_list_screen.dart';
import '../../categories_screen.dart';

class _CategoryItem {
  final String id;
  final String name;
  final String image;

  _CategoryItem({required this.id, required this.name, required this.image});
}

class CategoryGrid extends StatefulWidget {
  final HomepageSection section;

  const CategoryGrid({super.key, required this.section});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  String _selectedMainCategoryFilter = 'All';

  // Soft pastel background card colors matching the design screenshot
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
  Widget build(BuildContext context) {
    if (widget.section.categories.isEmpty) return const SizedBox.shrink();

    final productProvider = Provider.of<ProductProvider>(context);
    final mainCategories = productProvider.mainCategories;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final titleColor = Theme.of(context).textTheme.titleLarge?.color ??
        (isDark ? Colors.white : const Color(0xFF0F172A));

    List<_CategoryItem> displayCategories = widget.section.categories
        .map((c) => _CategoryItem(id: c.id, name: c.name, image: c.image))
        .toList();

    if (_selectedMainCategoryFilter != 'All') {
      final selectedMain = mainCategories.firstWhere(
        (m) => m.name.toLowerCase() == _selectedMainCategoryFilter.toLowerCase(),
        orElse: () => mainCategories.first,
      );
      if (selectedMain.categories.isNotEmpty) {
        displayCategories = selectedMain.categories
            .map((c) => _CategoryItem(id: c.id, name: c.name, image: c.image))
            .toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header Row (Title + See More >) ──
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.r(16),
            vertical: context.r(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                widget.section.title.isNotEmpty ? widget.section.title : "Categories",
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CategoriesScreen()),
                  );
                },
                child: Row(
                  children: [
                    CustomText(
                      "See More",
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                    SizedBox(width: context.r(2)),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: context.r(18),
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Main Category Filter Chips (if available) ──
        if (mainCategories.length > 1) ...[
          SizedBox(height: context.r(4)),
          SizedBox(
            height: context.r(32),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: context.r(16)),
              children: [
                _buildFilterChip('All', isDark, primaryColor),
                ...mainCategories.map((m) => _buildFilterChip(m.name, isDark, primaryColor)),
              ],
            ),
          ),
          SizedBox(height: context.r(10)),
        ] else
          SizedBox(height: context.r(8)),

        // ── Soft Pastel Category Cards Grid (4 Columns) ──
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.r(16)),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: context.r(14),
            crossAxisSpacing: context.r(12),
            childAspectRatio: 0.73,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) {
            final category = displayCategories[index];
            final color = _cardColors[index % _cardColors.length];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductListScreen(
                      title: category.name,
                      categoryId: category.id,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(context.r(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Soft Pastel Image Container
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? color.withValues(alpha: 0.18) : color,
                        borderRadius: BorderRadius.circular(context.r(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(context.r(10)),
                      child: Center(
                        child: SmartImage(
                          imageUrl: category.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: context.r(6)),

                  // Category Name Below Card
                  Expanded(
                    child: CustomText(
                      category.name,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: context.r(16)),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isDark, Color primaryColor) {
    final isSelected = _selectedMainCategoryFilter.toLowerCase() == label.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMainCategoryFilter = label;
        });
      },
      child: Container(
        margin: EdgeInsets.only(right: context.r(6)),
        padding: EdgeInsets.symmetric(
          horizontal: context.r(12),
          vertical: context.r(5),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(context.r(16)),
          border: Border.all(
            color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: CustomText(
            label,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
