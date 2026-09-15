import 'package:flutter/material.dart';

/// Responsive size utility — use anywhere with `context.sp`, `context.w`, etc.
extension AppSizesExt on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Responsive horizontal fraction (0.0 – 1.0)
  double w(double fraction) => screenWidth * fraction;

  /// Responsive vertical fraction (0.0 – 1.0)
  double h(double fraction) => screenHeight * fraction;

  /// Scale font size relative to 390px design width
  double sp(double size) => size * (screenWidth / 390);

  /// Scale padding/margin relative to 390px design width
  double r(double size) => size * (screenWidth / 390);

  bool get isSmall => screenWidth < 360;
  bool get isMedium => screenWidth >= 360 && screenWidth < 480;
  bool get isLarge => screenWidth >= 480;

  EdgeInsets get pagePadding =>
      EdgeInsets.symmetric(horizontal: r(16), vertical: r(8));

  double get cardBorderRadius => isSmall ? r(10) : r(14);
}

/// Shorthand static access without context (use when context unavailable)
class AppSizes {
  AppSizes._();

  static double scaledFont(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.width / 390);
  }

  static double scaledSpace(BuildContext context, double size) {
    return size * (MediaQuery.of(context).size.width / 390);
  }
}
