import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import 'banner_slider.dart';
import 'category_grid.dart';
import 'product_scroll.dart';
import 'offer_strip.dart';

class HomepageSectionParser extends StatelessWidget {
  final HomepageSection section;

  const HomepageSectionParser({Key? key, required this.section})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!section.isActive) return const SizedBox.shrink();

    switch (section.type) {
      case 'BANNER_SLIDER':
      case 'SINGLE_BANNER':
        return BannerSlider(section: section);
      case 'CATEGORY_GRID':
        return CategoryGrid(section: section);
      case 'PRODUCT_SCROLL':
      case 'FLASH_SALE':
        return ProductScroll(section: section);
      case 'OFFER_STRIP':
        return OfferStrip(section: section);
      default:
        return const SizedBox.shrink();
    }
  }
}
