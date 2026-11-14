import 'package:flutter/material.dart';

class AppColors {
  // Deep Slate & Charcoal Palette
  static const Color backgroundTop = Color(0xFF0B0F19);
  static const Color backgroundBottom = Color(0xFF07090E);

  static const Color slate950 = Color(0xFF030712);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate850 = Color(0xFF141E33);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate50 = Color(0xFFF8FAFC);

  // Modern Glassmorphism surfaces
  static const Color glassSurface = Color(0x1AFFFFFF); // 10% white
  static const Color glassSurfaceSubtle = Color(0x0DFFFFFF); // 5% white
  static const Color glassBorder = Color(0x1FFFFFFF); // 12% white
  static const Color glassBorderLight = Color(0x33FFFFFF); // 20% white

  // Accent & Brand
  static const Color sky400 = Color(0xFF38BDF8);
  static const Color sky500 = Color(0xFF0EA5E9);
  static const Color sky300 = Color(0xFF7DD3FC);
  static const Color indigo500 = Color(0xFF6366F1);

  // Weather & Temperature range colors (iOS weather inspired)
  static const Color amber400 = Color(0xFFFBBF24); // Sunny
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color tempHot = Color(0xFFF87171);   // High temp
  static const Color tempWarm = Color(0xFFFBBF24);  // Warm temp
  static const Color tempMild = Color(0xFF34D399);  // Mild temp
  static const Color tempCool = Color(0xFF38BDF8);  // Cool temp
  static const Color tempCold = Color(0xFF60A5FA);  // Low temp

  // Rain Alert (50%+)
  static const Color rainHighBg = Color(0x330284C7);
  static const Color rainHighGlow = Color(0x8038BDF8);
  static const Color rainHighBorder = Color(0xFF38BDF8);

  // Status
  static const Color offlineBg = Color(0x26F59E0B);
  static const Color offlineText = Color(0xFFFCD34D);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundTop,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.sky400,
        surface: AppColors.slate900,
        onSurface: AppColors.slate50,
        outline: AppColors.glassBorder,
      ),
      cardTheme: CardThemeData(
        color: AppColors.slate900,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.slate50,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.slate900,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorderLight, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.glassBorder,
        thickness: 0.5,
        space: 1,
      ),
    );
  }
}
