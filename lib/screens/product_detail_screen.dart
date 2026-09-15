import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/shimmer_loaders.dart';
import '../utils/cart_animation_helper.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ProductVariantModel _selectedVariant;
  int _activeImageIndex = 0;
  bool _isFavorite = false;

  List<ReviewModel> _reviews = [];
  double _currentRating = 4.6;
  int _currentReviewCount = 0;
  bool _isLoadingReviews = true;

  List<ProductModel> _similarProducts = [];
  bool _isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.defaultVariant;
    _currentRating = widget.product.rating;
    _currentReviewCount = widget.product.reviewCount;
    _reviews = List.from(widget.product.reviews);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
      _loadSimilarProducts();
    });
  }

  Future<void> _loadReviews() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final data = await productProvider.fetchProductReviews(widget.product.id);
    if (mounted) {
      setState(() {
        _currentRating = data['rating'] ?? _currentRating;
        _currentReviewCount = data['reviewCount'] ?? _currentReviewCount;
        _reviews = data['reviews'] ?? _reviews;
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadSimilarProducts() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final similar = await productProvider.fetchSimilarProducts(widget.product.id);
    if (mounted) {
      setState(() {
        _similarProducts = similar;
        _isLoadingSimilar = false;
      });
    }
  }

  void _showAddReviewSheet(BuildContext context) {
    double selectedRating = 5.0;
    final nameController = TextEditingController();
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final primaryColor = Theme.of(context).primaryColor;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Write a Remark & Rating",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.name,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Star Rating Selector
                  const Text(
                    "Your Rating",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      final starVal = index + 1.0;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setSheetState(() => selectedRating = starVal);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(
                            selectedRating >= starVal ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: const Color(0xFFEAB308),
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Name Input
                  const Text(
                    "Your Name",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "e.g. Rahul Sharma",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Comment / Remark Input
                  const Text(
                    "Your Remark / Review",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Share your experience with quality, packaging, freshness…",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final name = nameController.text.trim();
                              final comment = commentController.text.trim();
                              if (name.isEmpty || comment.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Please fill your name and remark")),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);
                              final productProvider = Provider.of<ProductProvider>(context, listen: false);
                              final success = await productProvider.submitProductReview(
                                widget.product.id,
                                userName: name,
                                rating: selectedRating,
                                comment: comment,
                              );

                              if (success) {
                                if (ctx.mounted) Navigator.pop(ctx);
                                HapticFeedback.mediumImpact();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Thank you! Your remark was published."),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                _loadReviews(); // Refresh review list
                              } else {
                                setSheetState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Failed to submit remark. Please retry.")),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "SUBMIT REMARK",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final int qty = cart.getQuantity(widget.product.id, _selectedVariant.size);

    final double price = _selectedVariant.price;
    final double? origPrice = _selectedVariant.originalPrice;
    final bool hasDiscount = origPrice != null && origPrice > price;
    final double savings = hasDiscount ? (origPrice - price) : 0;
    final double discountPct = hasDiscount ? ((origPrice - price) / origPrice) * 100 : 0;

    final primaryColor = Theme.of(context).primaryColor;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? Colors.white : const Color(0xFF1E293B);
    final titleColor = isLight ? const Color(0xFF0F172A) : Colors.white;
    final subtextColor = isLight ? const Color(0xFF64748B) : Colors.grey.shade400;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Top Image Carousel SliverAppBar
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: cardBg,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: titleColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              // Share Button
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: CircleAvatar(
                  backgroundColor: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                  child: IconButton(
                    icon: Icon(Icons.share_outlined, color: titleColor, size: 19),
                    onPressed: () {},
                  ),
                ),
              ),
              // Wishlist / Heart Button
              Container(
                margin: const EdgeInsets.only(right: 14, top: 8, bottom: 8),
                child: CircleAvatar(
                  backgroundColor: isLight ? Colors.white.withValues(alpha: 0.9) : Colors.black54,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.redAccent : titleColor,
                      size: 19,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isFavorite = !_isFavorite);
                    },
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: widget.product.images.isNotEmpty
                        ? PageView.builder(
                            itemCount: widget.product.images.length,
                            onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: widget.product.images[index],
                                fit: BoxFit.contain,
                                placeholder: (c, u) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (c, u, e) => const Center(
                                  child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                            child: const Center(
                              child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey),
                            ),
                          ),
                  ),

                  // Image Dots Indicator
                  if (widget.product.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(widget.product.images.length, (idx) {
                          final isActive = _activeImageIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isActive ? 22 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: isActive ? primaryColor : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Main Body
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fast Delivery + Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 14, color: primaryColor),
                            const SizedBox(width: 3),
                            Text(
                              "10 MINS DELIVERY",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.product.badge != null && widget.product.badge!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.product.badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      height: 1.2,
                    ),
                  ),

                  if (widget.product.brand != null && widget.product.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Brand: ${widget.product.brand!}",
                      style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Rating & Reviews Summary Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLight ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentRating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.star, color: Colors.white, size: 12),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "$_currentReviewCount verified remarks & ratings",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtextColor),
                        ),
                        const Spacer(),
                        const Icon(Icons.verified, color: Color(0xFF16A34A), size: 16),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "₹${price.toStringAsFixed(0)}",
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: titleColor),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          "MRP ₹${origPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${discountPct.toStringAsFixed(0)}% OFF",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        "You save ₹${savings.toStringAsFixed(0)} on this unit",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF16A34A), fontWeight: FontWeight.w600),
                      ),
                    ),

                  const SizedBox(height: 22),

                  // Variant / Pack Size Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Select Pack / Variant",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                      ),
                      Text(
                        "${widget.product.variants.length} available",
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.product.variants.map((v) {
                      final isSelected = v.size == _selectedVariant.size;
                      final bool vHasDiscount = (v.originalPrice ?? 0) > v.price;
                      final double vDisc = vHasDiscount ? (((v.originalPrice! - v.price) / v.originalPrice!) * 100) : 0;
                      final bool isOut = v.stock <= 0;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedVariant = v);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor.withValues(alpha: 0.08) : cardBg,
                            border: Border.all(
                              color: isSelected ? primaryColor : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    v.size,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? primaryColor : titleColor,
                                    ),
                                  ),
                                  if (vHasDiscount) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        "${vDisc.toStringAsFixed(0)}% OFF",
                                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "₹${v.price.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? primaryColor : titleColor,
                                    ),
                                  ),
                                  if (vHasDiscount) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      "₹${v.originalPrice!.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (isOut)
                                const Text(
                                  "Out of Stock",
                                  style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Product Specs / Highlights
                  Text(
                    "Product Highlights",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHighlightItem(Icons.verified_outlined, "100% Genuine", "Quality Assured", primaryColor),
                      _buildHighlightItem(Icons.replay_outlined, "Easy Returns", "At Your Doorstep", primaryColor),
                      _buildHighlightItem(Icons.shield_outlined, "FSSAI Certified", "Safe & Hygienic", primaryColor),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Product Description
                  Text(
                    "Product Information",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description ??
                        "Fresh, authentic, and handpicked quality grocery item delivered to your doorstep in minutes.",
                    style: TextStyle(fontSize: 13, color: subtextColor, height: 1.5),
                  ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Customer Remarks & Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer Remarks & Ratings",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: titleColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$_currentReviewCount remarks from verified buyers",
                            style: TextStyle(fontSize: 11, color: subtextColor),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showAddReviewSheet(context),
                        icon: Icon(Icons.edit_note, size: 16, color: primaryColor),
                        label: Text("Write Remark", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_isLoadingReviews)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                  else if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text("No remarks yet. Be the first to share your experience!"),
                      ),
                    )
                  else
                    Column(
                      children: _reviews.take(5).map((r) => _buildReviewCard(r, primaryColor)).toList(),
                    ),

                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Similar Products Carousel
                  Text(
                    "Similar Products",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "You might also like from this category",
                    style: TextStyle(fontSize: 11, color: subtextColor),
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingSimilar)
                    const ProductHorizontalShimmer()
                  else if (_similarProducts.isEmpty)
                    const SizedBox.shrink()
                  else
                    SizedBox(
                      height: 255,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _similarProducts.length,
                        itemBuilder: (context, index) {
                          final item = _similarProducts[index];
                          return Container(
                            width: 155,
                            margin: const EdgeInsets.only(right: 12, bottom: 4),
                            child: ProductCard(product: item),
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

      // Sticky Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Price column
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${price.toStringAsFixed(0)}",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: titleColor),
                  ),
                  Text(
                    "${_selectedVariant.size}${savings > 0 ? ' • Save ₹${savings.toStringAsFixed(0)}' : ''}",
                    style: TextStyle(
                      fontSize: 11,
                      color: savings > 0 ? const Color(0xFF16A34A) : subtextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Add / Qty Controller Button
              Expanded(
                child: qty == 0
                    ? ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          CartAnimationHelper.flyToCart(
                            context: context,
                            imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first : '',
                          );
                          cart.addItem(widget.product, _selectedVariant);
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                        label: const Text("ADD TO CART", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      )
                    : Row(
                        children: [
                          // Quantity controller pill
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    cart.removeItem(widget.product.id, _selectedVariant.size);
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "$qty",
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    cart.addItem(widget.product, _selectedVariant);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Go To Cart Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F172A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text("VIEW CART", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
  }

  Widget _buildHighlightItem(IconData icon, String title, String subtitle, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 8, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : 'U',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 13,
                    color: const Color(0xFFEAB308),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.3),
          ),
        ],
      ),
    );
  }
}
