import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color secondary = Color(0xFF06B6D4);
  static const Color accent = Color(0xFF8B5CF6);

  // Cores neutras
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF111827);
  static const Color grey900 = Color(0xFF111827);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey50 = Color(0xFFF9FAFB);

  // Cores de status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBg = Color(0xFFFFFFFF);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF000000).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Border Radius
  static BorderRadius radiusSm = BorderRadius.circular(8);
  static BorderRadius radiusMd = BorderRadius.circular(12);
  static BorderRadius radiusLg = BorderRadius.circular(16);
  static BorderRadius radiusXl = BorderRadius.circular(20);
  static BorderRadius radiusFull = BorderRadius.circular(100);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: white,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: white,
        foregroundColor: black,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: black,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: black, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: black, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: black),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: black),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: black),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: black),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: grey800),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: grey700, height: 1.5),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: grey600),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: grey200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: grey200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: error, width: 2)),
        hintStyle: const TextStyle(color: grey400, fontSize: 14),
        labelStyle: const TextStyle(color: grey500, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: grey200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primary,
        unselectedItemColor: grey400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
