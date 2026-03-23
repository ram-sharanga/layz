// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      brightness:           Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.accent,
        secondary:  AppColors.accent,
        surface:    AppColors.surface,
        background: AppColors.background,
        error:      AppColors.error,
      ),
      textTheme:    GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
      splashColor:              Colors.transparent,
      highlightColor:           Colors.transparent,
      dividerColor:             AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation:       0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dialogBackgroundColor: AppColors.surface,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: GoogleFonts.dmSans(color: AppColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}