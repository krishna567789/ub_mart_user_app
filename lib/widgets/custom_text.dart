import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A modern, responsive Google Fonts Poppins-based text widget.
/// Use this everywhere instead of [Text] to keep typography consistent, clean, and elegant.
///
/// Examples:
/// ```dart
/// CustomText('Hello World', fontSize: 16, fontWeight: FontWeight.bold)
/// CustomText.title('Category Title')
/// CustomText.price('₹299')
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
  final TextStyle? style;

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
    this.style,
  });

  // ── Named Constructors for Standardized Typography ──

  const CustomText.headline(
    this.text, {
    super.key,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w900,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height = 1.25,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = -0.5,
    this.decorationColor,
    this.softWrap = true,
    this.style,
  });

  const CustomText.title(
    this.text, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height = 1.3,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = -0.2,
    this.decorationColor,
    this.softWrap = true,
    this.style,
  });

  const CustomText.subtitle(
    this.text, {
    super.key,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height = 1.3,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = 0,
    this.decorationColor,
    this.softWrap = true,
    this.style,
  });

  const CustomText.body(
    this.text, {
    super.key,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w400,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height = 1.4,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = 0,
    this.decorationColor,
    this.softWrap = true,
    this.style,
  });

  const CustomText.caption(
    this.text, {
    super.key,
    this.fontSize = 10,
    this.fontWeight = FontWeight.w500,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height = 1.2,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = 0.2,
    this.decorationColor,
    this.softWrap = true,
    this.style,
  });

  const CustomText.price(
    this.text, {
    super.key,
    this.fontSize = 15,
    this.fontWeight = FontWeight.w900,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.overflow,
    this.height = 1.1,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = -0.3,
    this.decorationColor,
    this.softWrap = false,
    this.style,
  });

  const CustomText.badge(
    this.text, {
    super.key,
    this.fontSize = 9.5,
    this.fontWeight = FontWeight.w800,
    this.color,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.overflow,
    this.height = 1.1,
    this.decoration,
    this.fontStyle,
    this.letterSpacing = 0.4,
    this.decorationColor,
    this.softWrap = false,
    this.style,
  });

  const CustomText.bold(
    this.text, {
    super.key,
    this.fontSize = 14,
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
    this.style,
  }) : fontWeight = FontWeight.w800;

  const CustomText.semiBold(
    this.text, {
    super.key,
    this.fontSize = 13,
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
    this.style,
  }) : fontWeight = FontWeight.w600;

  const CustomText.medium(
    this.text, {
    super.key,
    this.fontSize = 12,
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
    this.style,
  }) : fontWeight = FontWeight.w500;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? const TextStyle();

    final textStyle = GoogleFonts.poppins(
      textStyle: baseStyle,
      fontSize: fontSize ?? baseStyle.fontSize,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      color: color ?? baseStyle.color,
      height: height ?? baseStyle.height,
      decoration: decoration ?? baseStyle.decoration,
      fontStyle: fontStyle ?? baseStyle.fontStyle,
      letterSpacing: letterSpacing ?? baseStyle.letterSpacing,
      decorationColor: decorationColor ?? baseStyle.decorationColor,
    );

    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: textStyle,
    );
  }
}

/// Helper class for backwards-compatibility with existing calls
class AppText {
  AppText._();

  static Widget headline(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText.headline(text, color: color, textAlign: align, maxLines: maxLines);

  static Widget title(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText.title(text, color: color, textAlign: align, maxLines: maxLines);

  static Widget subtitle(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText.subtitle(text, color: color, textAlign: align, maxLines: maxLines);

  static Widget body(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText.body(text, color: color, textAlign: align, maxLines: maxLines);

  static Widget caption(String text, {Color? color, TextAlign? align, int? maxLines}) =>
      CustomText.caption(text, color: color, textAlign: align, maxLines: maxLines);

  static Widget price(String text, {Color? color}) =>
      CustomText.price(text, color: color);

  static Widget badge(String text, {Color? color}) =>
      CustomText.badge(text, color: color);
}
