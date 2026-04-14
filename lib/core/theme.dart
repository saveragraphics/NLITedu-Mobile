import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch 01 "Editorial EdTech" Design System
/// Exact tokens from Design_Specs/nexgen_aurora/DESIGN.md
class AppTheme {
  // ─── Color Tokens (exact hex from Stitch design spec) ───
  static const Color primary = Color(0xFF4800B2);
  static const Color primaryContainer = Color(0xFF6200EE);
  static const Color secondary = Color(0xFF7743B5);
  static const Color secondaryContainer = Color(0xFFBC87FE);
  static const Color tertiary = Color(0xFF003A80);
  static const Color tertiaryContainer = Color(0xFF0050AD);

  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFC);
  static const Color surfaceContainerHigh = Color(0xFFE5E7F6);
  static const Color surfaceContainerHighest = Color(0xFFDFE2F1);

  static const Color onSurface = Color(0xFF171B26);
  static const Color onSurfaceVariant = Color(0xFF494456);
  static const Color outline = Color(0xFF7A7488);
  static const Color outlineVariant = Color(0xFFCBC3D9);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static const Color primaryFixed = Color(0xFFE8DDFF);
  static const Color primaryFixedDim = Color(0xFFCFBDFF);
  static const Color secondaryFixed = Color(0xFFEEDBFF);
  static const Color tertiaryFixed = Color(0xFFD8E2FF);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: const Color(0xFFD0BEFF),
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: const Color(0xFF4D118B),
        tertiary: tertiary,
        onTertiary: Colors.white,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        error: error,
        errorContainer: errorContainer,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: TextTheme(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -1.5,
          height: 0.95,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -1,
          height: 1.0,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: onSurface,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: onSurfaceVariant,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: onSurfaceVariant,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: surfaceContainerLowest,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withOpacity(0.4), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: primary,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: onSurface),
      ),
    );
  }
}
