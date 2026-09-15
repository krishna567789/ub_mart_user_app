import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Flash Prime aesthetic static colors
  static Color primary = const Color(0xFF00FF66); // Neon Green
  static Color primaryLight = const Color(0xFF00FF66).withValues(alpha: 0.12);
  static Color primaryDark = const Color(0xFF00CC52);
  static Color accent = const Color(0xFFFFCC00); // Yellow/Gold Accent
  static Color accentLight = const Color(0xFFFFCC00).withValues(alpha: 0.12);
  static Color background = const Color(0xFF0F172A); // Very dark blue/slate
  static Color surface = const Color(0xFF1E293B); // Darker surface
  static Color textPrimary = const Color(0xFFF8FAFC); // Almost white
  static Color textSecondary = const Color(0xFF94A3B8); // Slate 400
  static Color border = const Color(0xFF334155); // Slate 700

  static ThemeData buildDynamicTheme({
    required Color primaryColor,
    required Color accentColor,
    required Color backgroundColor,
    required Color textPrimaryColor,
  }) {
    final isLight = backgroundColor.computeLuminance() > 0.5;
    final baseBrightness = isLight ? Brightness.light : Brightness.dark;
    final baseTextTheme = isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme;

    // Update global static accessors dynamically
    primary = primaryColor;
    primaryLight = primaryColor.withOpacity(0.12);
    final hsl = HSLColor.fromColor(primaryColor);
    primaryDark = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    accent = accentColor;
    accentLight = accentColor.withOpacity(0.12);
    background = backgroundColor;
    textPrimary = textPrimaryColor;
    textSecondary = isLight ? Colors.grey.shade600 : const Color(0xFF94A3B8);
    surface = isLight ? Colors.white : const Color(0xFF1E293B);
    border = isLight ? Colors.grey.shade200 : const Color(0xFF334155);

    return ThemeData(
      useMaterial3: true,
      brightness: baseBrightness,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: baseBrightness,
        primary: primaryColor,
        secondary: accentColor,
        surface: surface,
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: isLight ? Colors.white : Colors.black, // Contrast
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.poppins(color: isLight ? Colors.black87 : textPrimary, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
