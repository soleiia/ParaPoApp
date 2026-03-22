import 'package:flutter/material.dart';

class AppColors {
  static const blue       = Color(0xFF3B6FE0);
  static const blueDark   = Color(0xFF2A56C6);
  static const blueLight  = Color(0xFF5B8FF5);
  static const yellow     = Color(0xFFFFC200);
  static const yellowDark = Color(0xFFE6A800);
  static const red        = Color(0xFFE53935);
  static const white      = Color(0xFFFFFFFF);
  static const offWhite   = Color(0xFFF5F7FA);
  static const lightGrey  = Color(0xFFE8ECF2);
  static const textDark   = Color(0xFF1A1D2E);
  static const textMid    = Color(0xFF5A6280);
  static const textLight  = Color(0xFF9BA3C0);
  static const divider    = Color(0xFFECEFF8);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.offWhite,
    fontFamily: 'Helvetica Neue',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.offWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );
}
