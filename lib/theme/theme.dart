import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Background Colors (Grounded Dark) ──
  static const Color bgDeep = Color(0xFF121212);
  static const Color bgSurface = Color(0xFF1A1A1A);
  static const Color bgCard = Color(0xFF1E1E1E);
  static const Color bgField = Color(0xFF2C2C2C);

  // ── Accent Colors ──
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentIndigo = Color(0xFF6366F1);
  static const Color accentPurple = Color(0xFF8B5CF6);

  // ── Status Colors ──
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color sosRed = Color(0xFFE63946);

  // Aliases
  static const Color danger = error;
  static const Color dangerSoft = Color(0xFFFCA5A5);

  // ── Text Colors ──
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFFD1D5DB);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFF6B7280);
  static const Color textHint = Colors.white70;

  // ── Subtle border for card separation ──
  static BorderSide get cardBorder =>
      BorderSide(color: Colors.white.withAlpha(20));

  // ── Gradients (kept for semantic use only) ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentCyan],
  );

  static const LinearGradient alertGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [error, Color(0xFFF97316)],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF34D399)],
  );

  // ── Border Radius ──
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;

  // ── Spacing ──
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingXLarge = 20.0;
  static const double spacingXXLarge = 24.0;

  // ── Theme Data ──
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDeep,
      cardColor: bgCard,
      dividerColor: Colors.white.withAlpha(20),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
      ),
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentCyan,
        surface: bgSurface,
        error: error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textHint,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textHint,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgField,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXLarge,
            vertical: spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: textSecondary,
      ),
    );
  }

  // ── Light Theme ──
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    );

    const lightBg = Color(0xFFF5F7FA);
    const lightSurface = Color(0xFFFFFFFF);
    const lightTextPrimary = Color(0xFF1A1A1A);
    const lightTextSecondary = Color(0xFF6B7280);
    const lightTextMuted = Color(0xFF9CA3AF);

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      cardColor: lightSurface,
      dividerColor: Colors.black.withAlpha(20),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
      ),
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentCyan,
        surface: lightSurface,
        error: error,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          fontSize: 32, fontWeight: FontWeight.w800, color: lightTextPrimary,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w700, color: lightTextPrimary,
        ),
        displaySmall: baseTextTheme.displaySmall?.copyWith(
          fontSize: 24, fontWeight: FontWeight.w700, color: lightTextPrimary,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w700, color: lightTextPrimary,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 18, fontWeight: FontWeight.w700, color: lightTextPrimary,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w500, color: lightTextPrimary,
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w400, color: lightTextPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, color: lightTextSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w400, color: lightTextMuted,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, color: lightTextPrimary,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 10, fontWeight: FontWeight.w500, color: lightTextMuted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacingLarge,
          vertical: spacingMedium,
        ),
        hintStyle: const TextStyle(color: lightTextMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingXXLarge,
            vertical: spacingLarge,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
        ),
      ),
      iconTheme: const IconThemeData(
        color: lightTextSecondary,
      ),
    );
  }
}