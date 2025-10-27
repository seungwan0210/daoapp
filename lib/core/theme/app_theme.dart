// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    primaryColor: const Color(0xFF00D4FF),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: 'Pretendard',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF00D4FF),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    ),
  );
}