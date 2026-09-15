import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';
import '../../../widgets/smart_image.dart';

class BannerSlider extends StatefulWidget {
  final HomepageSection section;

  const BannerSlider({Key? key, required this.section}) : super(key: key);

  @override
  _BannerSliderState createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.section.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 12),

        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.section.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.section.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SmartImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.section.banners.asMap().entries.map((entry) {
            final isActive = _currentIndex == entry.key;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 18.0 : 6.0,
              height: 6.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
