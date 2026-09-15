import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_sizes.dart';

/// A responsive, Poppins-based text widget.
/// Use this everywhere instead of [Text] to keep fonts consistent.
///
/// Example:
/// ```dart
/// CustomText('Hello', fontSize: 16, fontWeight: FontWeight.bold)
/// ```
class CustomText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final TextDecoration? decoration;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final Color? decorationColor;
  final bool softWrap;

  const CustomText(
    this.text, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.decoration,
    this.fontStyle,
    this.letterSpacing,
    this.decorationColor,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    // Scale font size responsively; if no fontSize provided, let Poppins use theme default
    final double? scaledSize =
        fontSize != null ? AppSizes.scaledFont(context, fontSize!) : null;

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: GoogleFonts.poppins(
        fontSize: scaledSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        decoration: decoration,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        decorationColor: decorationColor,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Preset helpers for common usage patterns
// ──────────────────────────────────────────────

class AppText {
  AppText._();

  static Widget headline(String text, {Color? color, TextAlign? align}) =>
      CustomText(text,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: color,
          textAlign: align);

  static Widget title(String text, {Color? color, TextAlign? align}) =>
      CustomText(text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
          textAlign: align);

  static Widget subtitle(String text, {Color? color, TextAlign? align}) =>
      CustomText(text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
          textAlign: align);

  static Widget body(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText(text,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color,
          textAlign: align,
          maxLines: maxLines);

  static Widget caption(String text, {Color? color, TextAlign? align}) =>
      CustomText(text,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
          textAlign: align);

  static Widget price(String text, {Color? color}) =>
      CustomText(text,
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: color);

  static Widget badge(String text, {Color? color}) =>
      CustomText(text,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4);
}
