import 'package:flutter/material.dart';
import '../../../models/homepage_section.dart';

class OfferStrip extends StatelessWidget {
  final HomepageSection section;

  const OfferStrip({Key? key, required this.section}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (section.offerText.isEmpty) return const SizedBox.shrink();

    Color bgColor = Theme.of(context).colorScheme.primary;
    if (section.bgColor.isNotEmpty) {
      try {
        bgColor = Color(int.parse(section.bgColor.replaceAll('#', '0xff')));
      } catch (e) {
        // Fallback to primary
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor, style: BorderStyle.solid, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer, color: bgColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              section.offerText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: bgColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
