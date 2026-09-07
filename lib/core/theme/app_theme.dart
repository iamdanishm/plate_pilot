import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Palette (Culinary Emerald & Saffron Accent)
  static const Color primaryEmerald = Color(0xFF0D6E4F);
  static const Color primaryEmeraldLight = Color(0xFF16A34A);
  static const Color primaryEmeraldDark = Color(0xFF064E3B);

  static const Color secondaryAmber = Color(0xFFEAB308);
  static const Color secondaryAmberDark = Color(0xFFCA8A04);
  static const Color accentTangerine = Color(0xFFF97316);

  static const Color neutralBackgroundLight = Color(0xFFF8FAF9);
  static const Color neutralSurfaceLight = Color(0xFFFFFFFF);
  static const Color neutralSurfaceVariantLight = Color(0xFFEFF3F1);

  static const Color neutralBackgroundDark = Color(0xFF0F1715);
  static const Color neutralSurfaceDark = Color(0xFF16221F);
  static const Color neutralSurfaceVariantDark = Color(0xFF1E2E2A);

  // Liquid Glass Specific Colors (iOS)
  static const Color glassWhite10 = Color(0x1AFFFFFF);
  static const Color glassWhite20 = Color(0x33FFFFFF);
  static const Color glassWhite40 = Color(0x66FFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x1FFFFFFF);

  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static TextStyle fontStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    if (!GoogleFonts.config.allowRuntimeFetching) {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Light Theme (Material 3 Expressive base)
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primaryEmerald,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD1FAE5),
      onPrimaryContainer: primaryEmeraldDark,
      secondary: secondaryAmberDark,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),
      tertiary: accentTangerine,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFEDD5),
      onTertiaryContainer: const Color(0xFF7C2D12),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF991B1B),
      surface: neutralSurfaceLight,
      onSurface: const Color(0xFF1C2826),
      surfaceContainerHighest: neutralSurfaceVariantLight,
      onSurfaceVariant: const Color(0xFF4B635D),
      outline: const Color(0xFF748C85),
      outlineVariant: const Color(0xFFC7D7D2),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutralBackgroundLight,
      textTheme: _buildTextTheme(colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: isIOS,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: fontStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isIOS ? 0 : 2,
        color: neutralSurfaceLight,
        shadowColor: primaryEmerald.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 18 : 24),
          side: isIOS
              ? BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 1)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: isIOS ? 0 : 2,
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isIOS ? 14 : 20),
          ),
          textStyle: fontStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isIOS ? 14 : 20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryEmerald,
          side: const BorderSide(color: primaryEmerald, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isIOS ? 14 : 20),
          ),
          textStyle: fontStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralSurfaceVariantLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: const BorderSide(color: primaryEmerald, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: isIOS ? Colors.transparent : neutralSurfaceLight,
        indicatorColor: const Color(0xFFD1FAE5),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return fontStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primaryEmerald,
            );
          }
          return fontStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          );
        }),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primaryEmeraldLight,
      onPrimary: const Color(0xFF003822),
      primaryContainer: primaryEmeraldDark,
      onPrimaryContainer: const Color(0xFFA7F3D0),
      secondary: secondaryAmber,
      onSecondary: const Color(0xFF451A03),
      secondaryContainer: const Color(0xFF78350F),
      onSecondaryContainer: const Color(0xFFFEF3C7),
      tertiary: accentTangerine,
      onTertiary: const Color(0xFF431407),
      tertiaryContainer: const Color(0xFF7C2D12),
      onTertiaryContainer: const Color(0xFFFFEDD5),
      error: const Color(0xFFEF4444),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF7F1D1D),
      onErrorContainer: const Color(0xFFFEE2E2),
      surface: neutralSurfaceDark,
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerHighest: neutralSurfaceVariantDark,
      onSurfaceVariant: const Color(0xFF94A3B8),
      outline: const Color(0xFF64748B),
      outlineVariant: const Color(0xFF334155),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: neutralBackgroundDark,
      textTheme: _buildTextTheme(colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: isIOS,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: fontStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: neutralSurfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 18 : 24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmeraldLight,
          foregroundColor: const Color(0xFF003822),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isIOS ? 14 : 20),
          ),
          textStyle: fontStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: neutralSurfaceVariantDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isIOS ? 14 : 18),
          borderSide: const BorderSide(color: primaryEmeraldLight, width: 2),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color baseColor) {
    return TextTheme(
      displayLarge: fontStyle(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: baseColor,
      ),
      displayMedium: fontStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: baseColor,
      ),
      headlineMedium: fontStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: baseColor,
      ),
      titleLarge: fontStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: fontStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: baseColor,
      ),
      bodyMedium: fontStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: baseColor.withValues(alpha: 0.8),
      ),
      labelLarge: fontStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
    );
  }
}
