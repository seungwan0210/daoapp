// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:daoapp/di/service_locator.dart';
import 'package:daoapp/presentation/screens/splash_screen.dart';
import 'package:daoapp/presentation/screens/main_screen.dart';
import 'package:daoapp/presentation/screens/user/ranking_screen.dart';
import 'package:daoapp/presentation/screens/user/calendar_screen.dart';
import 'package:daoapp/presentation/screens/login/login_screen.dart';
import 'package:daoapp/core/theme/app_theme.dart'; // 테마 추가!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  setupDependencies();
  runApp(
    const ProviderScope(
      child: DaoApp(),
    ),
  );
}

class DaoApp extends StatelessWidget {
  const DaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAO App - Steel League',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light, // 여기서 테마 통일!
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.ranking: (context) => const RankingScreen(),
        AppRoutes.calendar: (context) => const CalendarScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      },
    );
  }
}

// 라우트 상수
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String main = '/main';
  static const String ranking = '/ranking';
  static const String calendar = '/calendar';
}