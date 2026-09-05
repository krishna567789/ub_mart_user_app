import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Static color references for backward compatibility with existing code (will be overwritten by dynamic theme)
  static const Color primary = Color(0xFF0C831F); // Instamart/Blinkit Green
  static const Color primaryLight = Color(0xFFE8F5E9);
  static const Color primaryDark = Color(0xFF075B14);
  static const Color accent = Color(0xFFFF6D00); // Bright Orange Accent
  static const Color accentLight = Color(0xFFFFF3E0);
  static const Color background = Color(0xFFF4F6F8);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static ThemeData buildDynamicTheme({
    required Color primaryColor,
    required Color accentColor,
    required Color backgroundColor,
    required Color textPrimaryColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
        error: Colors.redAccent,
        background: backgroundColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF6B7280),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimaryColor),
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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
        backgroundColor: textPrimaryColor,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
