import 'package:flutter/material.dart';

class AppColors {
  // Slate palette
  static const Color slate950 = Color(0xFF020617);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate850 = Color(0xFF161F30);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Accents
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky900 = Color(0xFF0C4A6E);

  // Weather indicator colors
  static const Color amber400 = Color(0xFFFBBF24); // Sunny
  static const Color red400 = Color(0xFFF87171);   // High temp
  static const Color blue400 = Color(0xFF60A5FA);  // Low temp
  static const Color rainHighBg = Color(0x330284C7); // >= 50% precip
  static const Color rainHighBorder = Color(0xFF38BDF8);
  static const Color offlineBg = Color(0x33F59E0B);
  static const Color offlineText = Color(0xFFFCD34D);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.slate900,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.sky400,
        onPrimary: AppColors.slate950,
        surface: AppColors.slate800,
        onSurface: AppColors.slate50,
        outline: AppColors.slate700,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slate800,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.slate700, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.slate900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.slate50,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.slate850,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.slate700, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.slate700,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
