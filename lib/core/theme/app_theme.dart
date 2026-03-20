import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:layz/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.dark,
        surface: AppColors.surface,
      ),

      // Status bar: light icons on black background
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      textTheme: GoogleFonts.dmSansTextTheme(
        TextTheme(
          // Display — used for big headings like "LAYZ"
          displayLarge: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          // Title — screen headings
          titleLarge: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          // Body
          bodyMedium: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          // Caption / hints
          bodySmall: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // Input fields (used in onboarding)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
      ),

      // Divider
      dividerColor: AppColors.divider,
    );
  }
}