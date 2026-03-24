import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4A6CF7);
  static const Color darkText = Color(0xFF1E2A4A);
  static const Color subtitle = Color(0xFF8F9BB3);
  static const Color bodyText = Color(0xFF6B7A99);
  static const Color background = Color(0xFFF8F9FC);
  static const Color cardBg = Colors.white;
  static const Color border = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFF9FAFB);

  // Status colors
  static const Color statusPending = Color(0xFFF54900);
  static const Color statusPendingBg = Color(0xFFFFEDD4);
  static const Color statusConfirming = Color(0xFF155DFC);
  static const Color statusConfirmingBg = Color(0xFFDBEAFE);
  static const Color statusConfirmed = Color(0xFF00A63E);
  static const Color statusConfirmedBg = Color(0xFFDCFCE7);
  static const Color statusActive = Color(0xFF155DFC);
  static const Color statusActiveBg = Color(0xFFDBEAFE);

  // Category icon backgrounds
  static const Color locationBg = Color(0x144A6CF7);
  static const Color languageBg = Color(0x146C5CE7);
  static const Color dateBg = Color(0x1400B894);
  static const Color industryBg = Color(0x14FDCB6E);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
                scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.cardBg,
          background: AppColors.background,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.darkText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
                      ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: Colors.black.withOpacity(0.1),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
            minimumSize: const Size(double.infinity, 56),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
                          ),
          ),
        ),
      );
}
