// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Pretendard',
    scaffoldBackgroundColor: Colors.white,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      primary: const Color(0xFF1565C0),
      secondary: const Color(0xFF42A5F5),
    ),

    // AppBar (기존 유지)
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
    ),

    // 입력창 (여백 최소화!)
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 16→6
      isDense: true,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      errorStyle: const TextStyle(fontSize: 11),
    ),

    // 카드 (여백 줄임)
    cardTheme: CardTheme(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.hardEdge,
    ),

    // 버튼
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

      // lib/core/theme/app_theme.dart
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),     // 20 → 15
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),   // 16 → 13
        bodyLarge: TextStyle(fontSize: 15, height: 1.3),                     // 14 → 13
        bodyMedium: TextStyle(fontSize: 14, height: 1.0, fontWeight: FontWeight.w500), // 14 → 12
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),

    // 바텀 네비
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF1565C0),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),
  );
}